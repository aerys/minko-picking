package aerys.minko.scene.visitor
{
	import aerys.minko.render.RenderTarget;
	import aerys.minko.render.effect.picking.PickingStyle;
	import aerys.minko.render.renderer.IRenderer;
	import aerys.minko.scene.action.ActionType;
	import aerys.minko.scene.action.IAction;
	import aerys.minko.scene.action.group.PickingRenderAction;
	import aerys.minko.scene.node.IScene;
	import aerys.minko.scene.node.group.PickableGroup;
	import aerys.minko.scene.visitor.data.LocalData;
	import aerys.minko.scene.visitor.data.RenderingData;
	import aerys.minko.scene.visitor.data.ViewportData;
	
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	import flash.utils.Dictionary;
	
	public class PickingVisitor implements ISceneVisitor
	{
		protected static const ACTION_TYPES				: uint		= ActionType.RECURSE | ActionType.UPDATE_LOCAL_DATA | ActionType.UPDATE_STYLE;
		protected static const PICKING_RENDER_ACTION	: IAction	= new PickingRenderAction();
		
		protected static const EVENT_CLICK		: uint = 1 << 0;
		protected static const EVENT_MOUSE_DOWN	: uint = 1 << 1;
		protected static const EVENT_MOUSE_UP	: uint = 1 << 2;
		protected static const EVENT_MOUSE_MOVE	: uint = 1 << 3;
		
		protected var _hasSetMouseEvents		: Boolean;
		
		protected var _localData 				: LocalData;
		protected var _worldData 				: Dictionary;
		protected var _renderingData			: RenderingData
		protected var _renderer					: IRenderer;
		
		protected var _bitmapData				: BitmapData;
		protected var _currentColor				: uint;
		
		protected var _stageX					: Number;
		protected var _stageY					: Number;
		protected var _pickingSceneNodes		: Vector.<PickableGroup>;
		
		protected var _eventsToDispatch			: uint;
		protected var _lastMouseOver			: PickableGroup;
		protected var _currentMouseOver			: PickableGroup;
		
		public function PickingVisitor() 
		{
			_pickingSceneNodes	= new Vector.<PickableGroup>();
			_eventsToDispatch	= 0;
		}
		
		public function get localData() : LocalData
		{
			return _localData;
		}
		
		public function get worldData() : Dictionary
		{
			return _worldData;
		}
		
		public function get renderingData() : RenderingData
		{
			return _renderingData;
		}
		
		public function processSceneGraph(scene			: IScene, 
										  localData		: LocalData, 
										  worldData		: Dictionary, 
										  renderingData	: RenderingData,
										  renderer		: IRenderer) : void
		{
			_localData		= localData;
			_worldData		= worldData;
			_renderingData	= renderingData;
			
			_hasSetMouseEvents = false;
			
			configure();
			renderSceneToBitmapData(scene);
			updateMouseOverElement();
			dispatchEvents();
		}
		
		protected function configure() : void
		{
			_pickingSceneNodes.length	= 0;
			_currentColor				= 0xFF000000;
			
			var viewportData : ViewportData = worldData[ViewportData];
			
			if (_bitmapData == null
				|| _bitmapData.width != viewportData.width 
				|| _bitmapData.height != viewportData.height)
			{
				_bitmapData = new BitmapData(viewportData.width, viewportData.height, false, 0);
			}
			
			if (!_hasSetMouseEvents)
			{
				var stage : Stage = viewportData.stage;
				stage.addEventListener(MouseEvent.MOUSE_DOWN,	onStageMouseDown);
				stage.addEventListener(MouseEvent.MOUSE_UP,		onStageMouseUp);
				stage.addEventListener(MouseEvent.CLICK,		onStageClick);
				stage.addEventListener(MouseEvent.MOUSE_MOVE,	onStageMouseMove);
				_hasSetMouseEvents = true;
			}
		}
		
		protected function renderSceneToBitmapData(scene : IScene) : void
		{
			visit(scene);
			_renderer.drawToBackBuffer();
			_renderer.presentIntoBitmapData(_bitmapData);
			
			var viewportData	: ViewportData = worldData[ViewportData];
			var backBuffer		: RenderTarget = viewportData.renderTarget;
			
			// fixme, the fct call should be something like backBuffer.clear();
			_renderer.clear();
		}
		
		protected function updateMouseOverElement() : void
		{
			var pixelColor : uint = _bitmapData.getPixel(_stageX, _stageY);
			
			_lastMouseOver = _currentMouseOver;
			
			if (pixelColor == 0)
			{
				_currentMouseOver = null;
			}
			else
			{
				var elementIndex : uint = (pixelColor / 20) - 1;
				_currentMouseOver = _pickingSceneNodes[elementIndex];
			}
		}
		
		protected function dispatchEvents() : void
		{
			if (_eventsToDispatch & EVENT_MOUSE_UP)
			{
				_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
			}
			
			if (_eventsToDispatch & EVENT_MOUSE_DOWN)
			{
				_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
			}
			
			if (_eventsToDispatch & EVENT_CLICK)
			{
				_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
			}
			
			if (_currentMouseOver != _lastMouseOver)
			{
				_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
				
				if (_lastMouseOver != null)
					_lastMouseOver.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			}
			else
			{
				_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
			}
			
			_eventsToDispatch = 0;
		}
		
		protected function onStageMouseUp(e : MouseEvent) : void
		{
			_eventsToDispatch |= EVENT_MOUSE_UP;
		}
		
		protected function onStageMouseDown(e : MouseEvent) : void
		{
			_eventsToDispatch |= EVENT_MOUSE_DOWN;	
		}
		
		protected function onStageClick(e : MouseEvent) : void
		{
			_eventsToDispatch |= EVENT_CLICK;
		}
		
		protected function onStageMouseMove(e : MouseEvent) : void
		{
			_stageX = e.stageX;
			_stageY = e.stageY;
			_eventsToDispatch |= EVENT_MOUSE_MOVE;
		}
		
		public function visit(scene : IScene) : void
		{
			var actions 	: Vector.<IAction> 	= scene.actions;
			var numActions	: int				= actions.length;
			
			var	i : int, action : IAction, actionType : uint;
			
			if (scene is PickableGroup)
			{
				_pickingSceneNodes.push(scene);
				_currentColor += 20;
				_renderingData.styleStack.set(PickingStyle.CURRENT_COLOR, _currentColor);
			}
			
			for (i = 0; i < numActions; ++i)
			{
				action		= actions[i];
				actionType	= action.type;
				
				if (actionType & ACTION_TYPES)
					action.prefix(scene, this, _renderer);
				else if (actionType & ActionType.RENDER)
					PICKING_RENDER_ACTION.prefix(scene, this, _renderer);
			}
			
			for (i = 0; i < numActions; ++i)
			{
				action		= actions[i];
				actionType	= action.type;
				
				if (actionType & ACTION_TYPES)
					action.infix(scene, this, _renderer);
				else if (actionType & ActionType.RENDER)
					PICKING_RENDER_ACTION.infix(scene, this, _renderer);
			}
			
			for (i = 0; i < numActions; ++i)
			
			{
				action		= actions[i];
				actionType	= action.type;
				
				if (actionType & ACTION_TYPES)
					action.postfix(scene, this, _renderer);
				else if (actionType & ActionType.RENDER)
					PICKING_RENDER_ACTION.postfix(scene, this, _renderer);
			}
		}
	}
}
