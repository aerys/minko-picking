package aerys.minko.scene.controller
{
	import aerys.minko.effect.PickingShader;
	import aerys.minko.ns.minko_scene;
	import aerys.minko.render.RenderTarget;
	import aerys.minko.render.effect.Effect;
	import aerys.minko.render.shader.ActionScriptShader;
	import aerys.minko.scene.controller.mesh.RenderingController;
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

	public class PickingController extends AbstractController
	{
		use namespace minko_scene;
		
		public static const DEFAULT_RATE		: Number				= 15.0;
		
		private static const PICKING_SHADER		: ActionScriptShader	= new PickingShader();
		private static const CONTROLLER			: RenderingController	= new RenderingController(
			new Effect(PICKING_SHADER)
		);
		
		private static const COLOR_INCREMENT	: uint					= 1;

		private static const EVENT_NONE			: uint					= 0;
		private static const EVENT_CLICK		: uint 					= 1 << 0;
		private static const EVENT_DOUBLE_CLICK	: uint 					= 1 << 1;
		private static const EVENT_MOUSE_DOWN	: uint 					= 1 << 2;
		private static const EVENT_MOUSE_UP		: uint 					= 1 << 3;
		private static const EVENT_MOUSE_MOVE	: uint 					= 1 << 4;
		private static const EVENT_MOUSE_OVER	: uint 					= 1 << 5;
		private static const EVENT_MOUSE_OUT	: uint 					= 1 << 6;
		private static const EVENT_MOUSE_WHEEL	: uint 					= 1 << 7;
		private static const EVENT_ROLL_OVER	: uint 					= 1 << 8;
		private static const EVENT_ROLL_OUT		: uint 					= 1 << 9;
		private static const EVENT_RIGHT_CLICK	: uint 					= 1 << 10;
		private static const EVENT_RIGHT_DOWN	: uint 					= 1 << 11;
		private static const EVENT_RIGHT_UP		: uint 					= 1 << 12;
		
		// static initializer
		{
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
		
		private var _mouseClick			: Signal			= new Signal();
		private var _mouseDoubleClick	: Signal			= new Signal();
		private var _mouseDown			: Signal			= new Signal();
		private var _mouseMove			: Signal			= new Signal();
		private var _mouseOver			: Signal			= new Signal();
		private var _mouseOut			: Signal			= new Signal();
		private var _mouseUp			: Signal			= new Signal();
		private var _mouseWheel			: Signal			= new Signal();
		private var _mouseRollOver		: Signal			= new Signal();
		private var _mouseRollOut		: Signal			= new Signal();
		private var _mouseRightClick	: Signal			= new Signal();
		private var _mouseRightDown		: Signal			= new Signal();
		private var _mouseRightUp		: Signal			= new Signal();
		
		public function get useHandCursor() : Boolean
		{
			return _useHandCursor;
		}
		public function set useHandCursor(value : Boolean) : void
		{
			_useHandCursor = false;
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
		
		public function get mouseRightClick() : Signal
		{
			return _mouseRightClick;
		}
		
		public function get mouseRightDown() : Signal
		{
			return _mouseRightDown;
		}
		
		public function get mouseRightUp() : Signal
		{
			return _mouseRightUp;
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
			dispatcher.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			dispatcher.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			dispatcher.addEventListener(MouseEvent.CLICK, clickHandler);
			dispatcher.addEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler);
			dispatcher.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			dispatcher.addEventListener(MouseEvent.MOUSE_WHEEL,	mouseWheelHandler);
			dispatcher.addEventListener(MouseEvent.RIGHT_CLICK,	mouseRightClickHandler);
			dispatcher.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, mouseRightMouseDownHandler);
			dispatcher.addEventListener(MouseEvent.RIGHT_MOUSE_UP, mouseRightMouseUpHandler);
		}
		
		public function unbindDefaultInputs(dispatcher : IEventDispatcher) : void
		{
			dispatcher.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			dispatcher.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
			dispatcher.removeEventListener(MouseEvent.CLICK, clickHandler);
			dispatcher.removeEventListener(MouseEvent.DOUBLE_CLICK, doubleClickHandler);
			dispatcher.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
			dispatcher.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
			dispatcher.removeEventListener(MouseEvent.RIGHT_CLICK, mouseRightClickHandler);
			dispatcher.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, mouseRightMouseDownHandler);
			dispatcher.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, mouseRightMouseUpHandler);
		}
		
		private function targetAddedHandler(controller 	: PickingController,
											target		: Group) : void
		{
			target.childAdded.add(childAddedHandler);

			// fetch meshes
			var meshes : Vector.<ISceneNode> = target.getDescendantsByType(
				Mesh
			);
			var numMeshes : int = meshes.length;
			
			for (var meshId : int = 0; meshId < numMeshes; ++meshId)
				meshAddedHandler(meshes[meshId] as Mesh);
		}
		
		private function targetRemovedHandler(controller 	: PickingController,
											  target		: Group) : void
		{
			target.childAdded.remove(childAddedHandler);
		}

		private function childAddedHandler(parent 	: Group,
										   child	: ISceneNode) : void
		{
			if (child is Mesh)
				meshAddedHandler(child as Mesh);
		}
		
		private function meshAddedHandler(mesh : Mesh) : void
		{
			if (mesh.root is Scene)
				meshAddedToSceneHandler(mesh, mesh.root as Scene);
			else
				mesh.addedToScene.add(meshAddedToSceneHandler);
		}
		
		private function meshAddedToSceneHandler(mesh 	: Mesh,
												 scene 	: Scene) : void
		{
			_pickingId += COLOR_INCREMENT;
			
			mesh.removedFromScene.add(meshRemovedFromSceneHandler);
			mesh.bindings.setProperty("picking id", _pickingId);
			_idToMesh[int(_pickingId - 1)] = mesh;
			
			CONTROLLER.addTarget(mesh);
		}
		
		private function meshRemovedFromSceneHandler(mesh 	: Mesh,
												   	 scene 	: Scene) : void
		{
			CONTROLLER.removeTarget(mesh);
			mesh.removedFromScene.remove(meshRemovedFromSceneHandler);
		}
		
		private static function cleanPickingMap(shader		: ActionScriptShader,
												context		: Context3D,
												backBuffer	: RenderTarget) : void
		{
			context.clear();
		}
		
		private static function updatePickingMap(shader		: ActionScriptShader,
										  		 context	: Context3D,
										  		 backBuffer	: RenderTarget) : void
		{
			var width 	: Number	= backBuffer.width;
			var height 	: Number 	= backBuffer.height;
			var color 	: uint		= backBuffer.backgroundColor;
			
			if (!_bitmapData || _bitmapData.width != width || _bitmapData.height != height)
				_bitmapData = new BitmapData(width, height, false, 0);
			
			context.drawToBitmapData(_bitmapData);
			context.clear(
				(color >>> 16) / 255.,
				((color >> 8) & 0xff) / 255.,
				(color & 0xff) / 255.
			);
			
			PICKING_SHADER.enabled = false;
		}
		
		private function shaderEndHandler(shader		: ActionScriptShader,
										  context		: Context3D,
										  backBuffer	: RenderTarget) : void
		{
			if (_waitingForDispatch != EVENT_NONE)
			{
				updateMouseOverElement();
				executeSignals();
			}
		}
		
		override public function tick(target : ISceneNode, time : Number) : void
		{
			var deltaT 	: Number 	= time - _lastPickingTime;
			var enabled : Boolean 	= deltaT > 1000. / _pickingRate;
			
			enabled &&= _waitingForDispatch != EVENT_NONE;
			
			PICKING_SHADER.enabled ||= enabled;
			if (enabled)
				_lastPickingTime = time;
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
			if (_currentMouseOver != null && _useHandCursor)
				Mouse.cursor = MouseCursor.HAND;
			
			if (_lastMouseOver != null && _currentMouseOver != _lastMouseOver)
				_mouseRollOut.execute(this, _lastMouseOver, _mouseX, _mouseY);
			
			if (_currentMouseOver != null)
			{
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
			
			if (_waitingForDispatch & EVENT_RIGHT_CLICK)
				_mouseRightClick.execute(this, _currentMouseOver, _mouseX, _mouseY);
			
			if (_waitingForDispatch & EVENT_RIGHT_DOWN)
				_mouseRightDown.execute(this, _currentMouseOver, _mouseX, _mouseY);
			
			if (_waitingForDispatch & EVENT_RIGHT_UP)
				_mouseRightUp.execute(this, _currentMouseOver, _mouseX, _mouseY);
			
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
			if (_mouseMove.numCallbacks == 0 && _mouseOver.numCallbacks == 0
			    && _mouseOut.numCallbacks == 0 && _mouseRollOver.numCallbacks == 0
				&& _mouseRollOut.numCallbacks == 0)
				return ;
			
			_waitingForDispatch |= EVENT_MOUSE_MOVE | EVENT_MOUSE_OVER | EVENT_MOUSE_OUT;
			_mouseX = e.localX;
			_mouseY = e.localY;
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
		
		private function mouseRightClickHandler(e : MouseEvent) : void
		{
			_waitingForDispatch |= EVENT_RIGHT_CLICK;
			_mouseX = e.localX;
			_mouseY = e.localY;
		}
		
		private function mouseRightMouseDownHandler(e : MouseEvent) : void
		{
			_waitingForDispatch |= EVENT_RIGHT_DOWN;
			_mouseX = e.localX;
			_mouseY = e.localY;
		}
		
		private function mouseRightMouseUpHandler(e : MouseEvent) : void
		{
			_waitingForDispatch |= EVENT_RIGHT_UP;
			_mouseX = e.localX;
			_mouseY = e.localY;
		}
	}
}