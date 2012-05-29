package aerys.minko.scene.controller
{
	import aerys.minko.effect.PickingShader;
	import aerys.minko.ns.minko_scene;
	import aerys.minko.render.RenderTarget;
	import aerys.minko.render.Viewport;
	import aerys.minko.render.effect.Effect;
	import aerys.minko.render.resource.Context3DResource;
	import aerys.minko.render.shader.Shader;
	import aerys.minko.scene.node.Group;
	import aerys.minko.scene.node.ISceneNode;
	import aerys.minko.scene.node.Scene;
	import aerys.minko.scene.node.mesh.Mesh;
	import aerys.minko.type.Signal;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;

	public class PickingController extends EnterFrameController
	{
		use namespace minko_scene;
		
		public static const DEFAULT_RATE		: Number	= 15.0;
		
		private static const PICKING_SHADER		: Shader	= new PickingShader();
		private static const COLOR_INCREMENT	: uint		= 1;

		private static const EVENT_NONE			: uint		= 0;
		private static const EVENT_CLICK		: uint 		= 1 << 0;
		private static const EVENT_DOUBLE_CLICK	: uint 		= 1 << 1;
		private static const EVENT_MOUSE_DOWN	: uint 		= 1 << 2;
		private static const EVENT_MOUSE_UP		: uint 		= 1 << 3;
		private static const EVENT_MOUSE_MOVE	: uint 		= 1 << 4;
		private static const EVENT_MOUSE_OVER	: uint 		= 1 << 5;
		private static const EVENT_MOUSE_OUT	: uint 		= 1 << 6;
		private static const EVENT_MOUSE_WHEEL	: uint 		= 1 << 7;
		private static const EVENT_ROLL_OVER	: uint 		= 1 << 8;
		private static const EVENT_ROLL_OUT		: uint 		= 1 << 9;
		
		private static const TYPE_TO_MASK		: Object	= {};
		
		// static initializer
		{
			TYPE_TO_MASK[MouseEvent.CLICK] = EVENT_CLICK;
			TYPE_TO_MASK[MouseEvent.DOUBLE_CLICK] = EVENT_DOUBLE_CLICK;
			TYPE_TO_MASK[MouseEvent.MOUSE_DOWN] = EVENT_MOUSE_DOWN;
			TYPE_TO_MASK[MouseEvent.MOUSE_UP] = EVENT_MOUSE_UP;
			TYPE_TO_MASK[MouseEvent.MOUSE_MOVE] = EVENT_MOUSE_MOVE;
			TYPE_TO_MASK[MouseEvent.MOUSE_OVER] = EVENT_MOUSE_OVER;
			TYPE_TO_MASK[MouseEvent.MOUSE_OUT] = EVENT_MOUSE_OUT;
			TYPE_TO_MASK[MouseEvent.MOUSE_WHEEL] = EVENT_MOUSE_WHEEL;
			TYPE_TO_MASK[MouseEvent.ROLL_OVER] = EVENT_ROLL_OVER;
			TYPE_TO_MASK[MouseEvent.ROLL_OUT] = EVENT_ROLL_OUT;
			
			PICKING_SHADER.begin.add(cleanPickingMap);
			PICKING_SHADER.end.add(updatePickingMap);
		}
		
		private static var _pickingId	: int				= 0;
		private static var _bitmapData	: BitmapData		= null;
		
		private var _pickingRate		: Number			= 0.;
		private var _lastPickingTime	: Number			= 0.;
		private var _mouseX				: Number			= 0.;
		private var _mouseY				: Number			= 0.;
		
		private var _dispatcher			: EventDispatcher	= new EventDispatcher();
		private var _useHandCursor		: Boolean			= false;
		private var _subscribedEvents	: uint				= 0;
		private var _currentMouseOver	: Mesh				= null;
		private var _lastMouseOver		: Mesh				= null;
		private var _waitingForDispatch	: uint				= 0;
		private var _waitingWheelDelta	: int				= 0;
		
		private var _idToMesh			: Array				= [];
		
		private var _mouseClick			: Signal			= new Signal('PickingController.mouseClick');
		private var _mouseDoubleClick	: Signal			= new Signal('PickingController.mouseDoubleClick');
		private var _mouseDown			: Signal			= new Signal('PickingController.mouseDown');
		private var _mouseMove			: Signal			= new Signal('PickingController.mouseMove');
		private var _mouseOver			: Signal			= new Signal('PickingController.mouseOver');
		private var _mouseOut			: Signal			= new Signal('PickingController.mouseOut');
		private var _mouseUp			: Signal			= new Signal('PickingController.mouseUp');
		private var _mouseWheel			: Signal			= new Signal('PickingController.mouseWheel');
		private var _mouseRollOver		: Signal			= new Signal('PickingController.mouseRollOver');
		private var _mouseRollOut		: Signal			= new Signal('PickingController.mouseRollOut');
		
		public function get useHandCursor() : Boolean
		{
			return _useHandCursor;
		}
		public function set useHandCursor(value : Boolean) : void
		{
			_useHandCursor = value;
		}
		
		public function get mouseClick() : Signal
		{
			return _mouseClick;
		}
		
		public function get mouseDoubleClick() : Signal
		{
			return _mouseDoubleClick;
		}
		
		public function get mouseDown() : Signal
		{
			return _mouseDown;
		}
		
		public function get mouseMove() : Signal
		{
			return _mouseMove;
		}
		
		public function get mouseOver() : Signal
		{
			return _mouseOver;
		}
		
		public function get mouseOut() : Signal
		{
			return _mouseOut;
		}
		
		public function get mouseUp() : Signal
		{
			return _mouseUp;
		}
		
		public function get mouseWheel() : Signal
		{
			return _mouseWheel;
		}
		
		public function get mouseRollOver() : Signal
		{
			return _mouseRollOver;
		}
		
		public function get mouseRollOut() : Signal
		{
			return _mouseRollOut;
		}
		
		public function PickingController(pickingRate	: Number	= DEFAULT_RATE)
		{
			super();
			
			_pickingRate = pickingRate;
			
			initialize();
		}
		
		private function initialize() : void
		{
			PICKING_SHADER.end.add(shaderEndHandler);
			
			// listen for new targets
			targetAdded.add(targetAddedHandler);
			targetRemoved.add(targetRemovedHandler);
		}
		
		public function bindDefaultInputs(dispatcher : IEventDispatcher) : void
		{
			// listen for mouse events
			dispatcher.addEventListener(
				MouseEvent.MOUSE_DOWN,
				mouseDownHandler
			);
			dispatcher.addEventListener(
				MouseEvent.MOUSE_UP,
				mouseUpHandler
			);
			dispatcher.addEventListener(
				MouseEvent.CLICK,
				clickHandler
			);
			dispatcher.addEventListener(
				MouseEvent.DOUBLE_CLICK,
				doubleClickHandler
			);
			dispatcher.addEventListener(
				MouseEvent.MOUSE_MOVE,
				mouseMoveHandler
			);
			dispatcher.addEventListener(
				MouseEvent.MOUSE_WHEEL,
				mouseWheelHandler
			);
		}
		
		public function unbindDefaultInputs(dispatcher : IEventDispatcher) : void
		{
			dispatcher.removeEventListener(
				MouseEvent.MOUSE_DOWN,
				mouseDownHandler
			);
			dispatcher.removeEventListener(
				MouseEvent.MOUSE_UP,
				mouseUpHandler
			);
			dispatcher.removeEventListener(
				MouseEvent.CLICK,
				clickHandler
			);
			dispatcher.removeEventListener(
				MouseEvent.DOUBLE_CLICK,
				doubleClickHandler
			);
			dispatcher.removeEventListener(
				MouseEvent.MOUSE_MOVE,
				mouseMoveHandler
			);
			dispatcher.removeEventListener(
				MouseEvent.MOUSE_WHEEL,
				mouseWheelHandler
			);
		}
		
		override protected function targetAddedHandler(controller 	: EnterFrameController,
													   target		: ISceneNode) : void
		{
			super.targetAddedHandler(controller, target);
			
			var group : Group = target as Group;
			
			group.descendantAdded.add(childAddedHandler);

			// fetch meshes
			var meshes : Vector.<ISceneNode> = group.getDescendantsByType(
				Mesh
			);
			var numMeshes : int = meshes.length;
			
			for (var meshId : int = 0; meshId < numMeshes; ++meshId)
				meshAddedHandler(meshes[meshId] as Mesh);
		}
		
		override protected function targetRemovedHandler(controller : EnterFrameController,
														 target		: ISceneNode) : void
		{
			super.targetRemovedHandler(controller, target);
			
			(target as Group).descendantAdded.remove(childAddedHandler);
		}

		private function childAddedHandler(parent 	: Group,
										   child	: ISceneNode) : void
		{
			if (child is Mesh)
				meshAddedHandler(child as Mesh);
			if (child is Group)
				groupAddedHandler(child as Group);
		}
		
		private function meshAddedHandler(mesh : Mesh) : void
		{
			if (mesh.root is Scene)
				meshAddedToSceneHandler(mesh, mesh.root as Scene);
			else
				mesh.addedToScene.add(meshAddedToSceneHandler);
		}
		
		private function groupAddedHandler(group : Group) : void
		{
			var meshes 		: Vector.<ISceneNode> 	= group.getDescendantsByType(Mesh);
			var numMeshes	: uint 					= meshes.length;
			
			for each(var node : ISceneNode in meshes)
				meshAddedHandler(Mesh(node));
		}
		
		private function meshAddedToSceneHandler(mesh 	: Mesh,
												 scene 	: Scene) : void
		{
			if (!mesh.effect.hasPass(PICKING_SHADER))
				mesh.effect.addPass(PICKING_SHADER);
			
			if (!mesh.effectChanged.hasCallback(meshEffectChangedHandler))
			{
				_pickingId += COLOR_INCREMENT;
				
				mesh.removedFromScene.add(meshRemovedFromSceneHandler);
				mesh.properties.setProperty('pickingId', _pickingId);
				_idToMesh[int(_pickingId - 1)] = mesh;
			
				mesh.effectChanged.add(meshEffectChangedHandler);
			}
		}
		
		private function meshRemovedFromSceneHandler(mesh 	: Mesh,
												   	 scene 	: Scene) : void
		{
			// FIXME! Test if other meshes are sharing the same effect
		//	mesh.effect.removePass(PICKING_SHADER);
			mesh.effectChanged.remove(meshEffectChangedHandler);
			mesh.removedFromScene.remove(meshRemovedFromSceneHandler);
		}
		
		private function meshEffectChangedHandler(mesh		: Mesh,
												  oldEffect	: Effect,
												  newEffect	: Effect) : void
		{
			oldEffect.removePass(PICKING_SHADER);
			newEffect.addPass(PICKING_SHADER);
		}
		
		private static function cleanPickingMap(shader		: Shader,
												context		: Context3DResource,
												backBuffer	: RenderTarget) : void
		{
			context.clear();
		}
		
		private static function updatePickingMap(shader		: Shader,
										  		 context	: Context3DResource,
										  		 backBuffer	: RenderTarget) : void
		{
			var width 	: Number	= backBuffer.width;
			var height 	: Number 	= backBuffer.height;
			var color 	: uint		= backBuffer.backgroundColor;
			
			if (!_bitmapData || _bitmapData.width != width || _bitmapData.height != height)
				_bitmapData = new BitmapData(width, height, false, 0);
			
			context.drawToBitmapData(_bitmapData);
			context.clear(
				(color >>> 24) / 255.,
				((color >> 16) & 0xff) / 255.,
				((color >> 8) & 0xff) / 255.,
				(color & 0xff) / 255.
			);
			
			PICKING_SHADER.enabled = false;
		}
		
		private function shaderEndHandler(shader		: Shader,
										  context		: Context3DResource,
										  backBuffer	: RenderTarget) : void
		{
			if (_waitingForDispatch != EVENT_NONE || _useHandCursor)
			{
				updateMouseOverElement();
				executeSignals();
			}
		}
		
		override protected function sceneEnterFrameHandler(scene	: Scene,
														   viewport	: Viewport,
														   target	: BitmapData,
														   time		: Number) : void
		{
			var deltaT 	: Number 	= time - _lastPickingTime;
			
			if (deltaT > 1000. / _pickingRate)
			{
				PICKING_SHADER.enabled ||= _waitingForDispatch != EVENT_NONE;
				_lastPickingTime = time;
			}
		}
		
		private function updateMouseOverElement() : void
		{
			var pixelColor : uint = _bitmapData.getPixel(_mouseX, _mouseY);
			
			_lastMouseOver = _currentMouseOver;
			
			if (pixelColor == 0)
				_currentMouseOver = null;
			else
			{
				var elementIndex : uint = (pixelColor / COLOR_INCREMENT) - 1;
				
				_currentMouseOver = _idToMesh[elementIndex];
			}
		}

		private function executeSignals() : void
		{
			if (_lastMouseOver != null && _currentMouseOver != _lastMouseOver)
				_mouseRollOut.execute(this, _lastMouseOver, _mouseX, _mouseY);
			
			if (_currentMouseOver != null)
			{
				if (_useHandCursor)
					Mouse.cursor = MouseCursor.HAND;
				
				_mouseOver.execute(this, _currentMouseOver, _mouseX, _mouseY);
				
				if (_currentMouseOver != _lastMouseOver)
					_mouseRollOver.execute(this, _currentMouseOver, _mouseX, _mouseY);
			}
				
			if (_waitingForDispatch & EVENT_MOUSE_UP)
				_mouseUp.execute(this, _currentMouseOver, _mouseX, _mouseY);
			
			if (_waitingForDispatch & EVENT_MOUSE_DOWN)
				_mouseDown.execute(this, _currentMouseOver, _mouseX, _mouseY);
			
			if (_waitingForDispatch & EVENT_CLICK)
				_mouseClick.execute(this, _currentMouseOver, _mouseX, _mouseY);
			
			if (_waitingForDispatch & EVENT_DOUBLE_CLICK)
				_mouseDoubleClick.execute(this, _currentMouseOver, _mouseX, _mouseY);
			
			
			if (_waitingForDispatch & EVENT_MOUSE_WHEEL)
			{
				_mouseWheel.execute(
					this,
					_currentMouseOver,
					_mouseX,
					_mouseY,
					_waitingWheelDelta
				);
			}
			
			_waitingForDispatch = 0;
		}
		
		private function mouseUpHandler(e : MouseEvent) : void
		{
			if (_mouseUp.numCallbacks == 0)
				return ;
			
			_waitingForDispatch |= EVENT_MOUSE_UP;
			_mouseX = e.localX;
			_mouseY = e.localY;
		}
		
		private function mouseDownHandler(e : MouseEvent) : void
		{
			if (_mouseDown.numCallbacks == 0)
				return ;
			
			_waitingForDispatch |= EVENT_MOUSE_DOWN;	
			_mouseX = e.localX;
			_mouseY = e.localY;
		}
		
		private function clickHandler(e : MouseEvent) : void
		{
			if (_mouseClick.numCallbacks == 0)
				return ;
			
			_waitingForDispatch |= EVENT_CLICK;
			_mouseX = e.localX;
			_mouseY = e.localY;
		}
		
		private function doubleClickHandler(e : MouseEvent) : void
		{
			if (_mouseDoubleClick.numCallbacks == 0)
				return ;
			
			_waitingForDispatch |= EVENT_DOUBLE_CLICK;
			_mouseX = e.localX;
			_mouseY = e.localY;
		}
		
		private function mouseMoveHandler(e : MouseEvent) : void
		{
			if (_mouseMove.numCallbacks != 0 || _mouseOver.numCallbacks != 0
			    || _mouseOut.numCallbacks != 0 || _mouseRollOver.numCallbacks != 0
				|| _mouseRollOut.numCallbacks != 0)
			{
				_waitingForDispatch |= EVENT_MOUSE_MOVE | EVENT_MOUSE_OVER | EVENT_MOUSE_OUT;
				_mouseX = e.localX;
				_mouseY = e.localY;
			}
			else if (_useHandCursor)
			{
				_mouseX = e.localX;
				_mouseY = e.localY;
			}
		}
		
		private function mouseWheelHandler(e : MouseEvent) : void
		{
			if (_mouseWheel.numCallbacks == 0)
				return ;
			
			_waitingForDispatch |= EVENT_MOUSE_WHEEL;
			_waitingWheelDelta = e.delta;
			_mouseX = e.localX;
			_mouseY = e.localY;
		}
	}
}