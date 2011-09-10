package aerys.minko.scene.visitor
{
	import aerys.minko.render.Viewport;
	import aerys.minko.render.effect.Style;
	import aerys.minko.render.effect.picking.PickingStyle;
	import aerys.minko.render.renderer.IRenderer;
	import aerys.minko.scene.action.ActionType;
	import aerys.minko.scene.action.IAction;
	import aerys.minko.scene.action.mesh.PickingAction;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.scene.data.RenderingData;
	import aerys.minko.scene.data.ViewportData;
	import aerys.minko.scene.node.IScene;
	import aerys.minko.scene.node.group.PickableGroup;
	
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.Dictionary;
	
	public class PickingVisitor implements ISceneVisitor
	{
		protected static const ACTION_TYPES_EXPLORE_PASS	: uint		= ActionType.RECURSE;
		protected static const ACTION_TYPES_RENDER_PASS		: uint		= ActionType.RECURSE | ActionType.UPDATE_LOCAL_DATA;
		
		protected static const PICKING_RENDER_ACTION		: IAction	= new PickingAction();
		protected static const COLOR_INCREMENT				: uint		= 1;
		protected static const RECTANGLE					: Rectangle = new Rectangle(0, 0, 10, 10);
		
		protected static const EVENT_CLICK					: uint = 1 << 0;
		protected static const EVENT_DOUBLE_CLICK			: uint = 1 << 1;
		protected static const EVENT_MOUSE_DOWN				: uint = 1 << 2;
		protected static const EVENT_MOUSE_MOVE				: uint = 1 << 3;
		protected static const EVENT_MOUSE_OUT				: uint = 1 << 4;
		protected static const EVENT_MOUSE_OVER				: uint = 1 << 5;
		protected static const EVENT_MOUSE_UP				: uint = 1 << 6;
		protected static const EVENT_MOUSE_WHEEL			: uint = 1 << 7;
		protected static const EVENT_ROLL_OVER				: uint = 1 << 8;
		protected static const EVENT_ROLL_OUT				: uint = 1 << 9;
		
		protected static const DRAW_EVERYTIME_EVENTS		: uint = 
			EVENT_MOUSE_MOVE | EVENT_MOUSE_OUT | EVENT_MOUSE_OVER | EVENT_ROLL_OVER | EVENT_ROLL_OUT;
		
		protected var _hasSetMouseEvents		: Boolean;
		protected var _refreshRate				: uint;
		protected var _refreshIndex				: uint;
		protected var _numNodes					: uint;
		
		protected var _currentPass				: uint;
		protected var _hadToDrawLastTime		: Boolean;
		
		protected var _transformData 				: TransformData;
		protected var _worldData 				: Dictionary;
		protected var _renderingData			: RenderingData
		protected var _renderer					: IRenderer;
		
		protected var _bitmapData				: BitmapData;
		protected var _currentColor				: uint;
		
		protected var _viewportX				: int;
		protected var _viewportY				: int;
		protected var _pickingSceneNodes		: Vector.<PickableGroup>;
		
		protected var _waitingForDispatchEvents	: uint;
		protected var _waitingWheelDelta		: int;
		protected var _subscribedEvents			: uint;
		protected var _lastMouseOver			: PickableGroup;
		protected var _currentMouseOver			: PickableGroup;
		
		public function get numNodes()		: uint				{ return _numNodes; }
		public function get transformData()		: TransformData			{ return _transformData; }
		public function get worldData()		: Dictionary		{ return _worldData; }
		public function get renderingData()	: RenderingData		{ return _renderingData; }
		public function get ancestors()		: Vector.<IScene>	{ return null; }
		
		public function PickingVisitor(refreshRate : uint = 1) 
		{
			_pickingSceneNodes			= new Vector.<PickableGroup>();
			_waitingForDispatchEvents	= 0;
			
			_refreshIndex				= 0;
			_refreshRate				= refreshRate;
			_numNodes					= 0;
			
			_viewportX = _viewportY		= 0;
		}
		
		
		public function processSceneGraph(scene			: IScene, 
										  transformData		: TransformData, 
										  worldData		: Dictionary, 
										  renderingData	: RenderingData,
										  renderer		: IRenderer) : void
		{
			if (++_refreshIndex < _refreshRate)
				return;
			
			_transformData			= transformData;
			_worldData			= worldData;
			_renderingData		= renderingData;
			_renderer			= renderer;
			
			_hasSetMouseEvents	= false;
			_refreshIndex		= 0;
			
			configure();
			
			if (!_hadToDrawLastTime)
			{
				exploreSceneGraphForEvents(scene);
				
				if (!((_waitingForDispatchEvents & _subscribedEvents) ||
					(_subscribedEvents & DRAW_EVERYTIME_EVENTS)))
				{
					_hadToDrawLastTime = false;
					return;
				}
				
				createRenderStates(scene);
			}
			else
			{
				createRenderStates(scene);
				if (!((_waitingForDispatchEvents & _subscribedEvents) ||
					(_subscribedEvents & DRAW_EVERYTIME_EVENTS)))
				{
					_hadToDrawLastTime = false;
					return;
				}
			}
			
			renderToBitmapData();
			updateMouseOverElement();
			dispatchEvents();
			_hadToDrawLastTime = true;
		}
		
		protected function configure() : void
		{
			_pickingSceneNodes.length	= 0;
			_currentColor				= 0;
			
			var viewportData	: ViewportData	= worldData[ViewportData];
			var viewport		: Viewport		= viewportData.viewport;
			var stage			: Stage			= viewportData.stage;
			
			if (_bitmapData == null
				|| _bitmapData.width != viewportData.width 
				|| _bitmapData.height != viewportData.height)
			{
				_bitmapData = new BitmapData(viewportData.width, viewportData.height, false, 0);
			}
			
			if (!_hasSetMouseEvents)
			{
				stage.addEventListener(MouseEvent.MOUSE_DOWN,	onStageMouseDown);
				stage.addEventListener(MouseEvent.MOUSE_UP,		onStageMouseUp);
				stage.addEventListener(MouseEvent.CLICK,		onStageClick);
				stage.addEventListener(MouseEvent.DOUBLE_CLICK,	onStageDoubleClick);
				stage.addEventListener(MouseEvent.MOUSE_MOVE,	onStageMouseMove);
				stage.addEventListener(MouseEvent.MOUSE_WHEEL,	onStageMouseWheel);
				
				_hasSetMouseEvents = true;
				
//				var b : Bitmap = new Bitmap(_bitmapData);
//				b.width = 300;
//				b.x = b.y = 100;
//				b.height = b.width * (_bitmapData.height / _bitmapData.width);
//				stage.addChild(b);
			}
			
			if (_waitingForDispatchEvents & EVENT_MOUSE_MOVE)
			{
				var point	 	: Point;
				point = new Point(stage.mouseX, stage.mouseY);
				point = viewport.globalToLocal(point);
				
				_viewportX = point.x;
				_viewportY = point.y;
			}
			
			RECTANGLE.x = _viewportX - 5;
			RECTANGLE.y = _viewportY - 5;
		}
		
		protected function exploreSceneGraphForEvents(scene : IScene) : void
		{
			_numNodes		= 0;
			_currentPass	= 0;
			visit(scene);
		}
		
		protected function createRenderStates(scene : IScene) : void
		{
			_numNodes		= 0;
			_currentPass	= 1;
			
			_renderingData.styleStack.push(new Style());
			_renderingData.styleStack.set(PickingStyle.CURRENT_COLOR, 0);
			_renderingData.styleStack.set(PickingStyle.RECTANGLE, RECTANGLE);
			
			_renderer.clear();
			
			visit(scene);
			
			_renderingData.styleStack.pop();
		}
		
		protected function renderToBitmapData() : void
		{
			_renderer.drawToBackBuffer();
			_renderer.dumpBackbuffer(_bitmapData);
		}
		
		protected function updateMouseOverElement() : void
		{
			var pixelColor : uint = _bitmapData.getPixel(_viewportX, _viewportY);
			
			_lastMouseOver = _currentMouseOver;
			if (pixelColor == 0)
			{
				_currentMouseOver = null;
			}
			else
			{
				var elementIndex : uint = (pixelColor / COLOR_INCREMENT) - 1;
				_currentMouseOver = _pickingSceneNodes[elementIndex];
			}
		}
		
		protected function dispatchEvents() : void
		{
			Mouse.cursor = 
				_currentMouseOver != null && _currentMouseOver.useHandCursor ? 
				MouseCursor.HAND : MouseCursor.AUTO;
			
			if (_lastMouseOver != null && _currentMouseOver != _lastMouseOver)
				_lastMouseOver.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OUT));
			
			if (_currentMouseOver != null)
			{
				_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_OVER));
				
				if (_waitingForDispatchEvents & EVENT_MOUSE_UP)
					_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_UP));
				
				if (_waitingForDispatchEvents & EVENT_MOUSE_DOWN)
					_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_DOWN));
				
				if (_waitingForDispatchEvents & EVENT_CLICK)
					_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
				
				if (_waitingForDispatchEvents & EVENT_DOUBLE_CLICK)
					_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.DOUBLE_CLICK));
				
				if (_currentMouseOver != _lastMouseOver)
					_currentMouseOver.dispatchEvent(new MouseEvent(MouseEvent.ROLL_OVER));
				
				if (_waitingForDispatchEvents & EVENT_MOUSE_WHEEL)
				{
					var wheelEvent : MouseEvent = new MouseEvent(MouseEvent.MOUSE_WHEEL);
					wheelEvent.delta = _waitingWheelDelta;
					_currentMouseOver.dispatchEvent(wheelEvent);
				}
			}
			
			_waitingForDispatchEvents = 0;
		}
		
		protected function onStageMouseUp(e : MouseEvent) : void
		{
			_waitingForDispatchEvents |= EVENT_MOUSE_UP;
		}
		
		protected function onStageMouseDown(e : MouseEvent) : void
		{
			_waitingForDispatchEvents |= EVENT_MOUSE_DOWN;	
		}
		
		protected function onStageClick(e : MouseEvent) : void
		{
			_waitingForDispatchEvents |= EVENT_CLICK;
		}
		
		protected function onStageDoubleClick(e : MouseEvent) : void
		{
			_waitingForDispatchEvents |= EVENT_DOUBLE_CLICK;
		}
		
		protected function onStageMouseMove(e : MouseEvent) : void
		{
			_waitingForDispatchEvents |= EVENT_MOUSE_MOVE;
		}
		
		protected function onStageMouseWheel(e : MouseEvent) : void
		{
			_waitingWheelDelta = e.delta;
			_waitingForDispatchEvents |= EVENT_MOUSE_WHEEL;
		}
		
		public function visit(scene : IScene) : void
		{
			if (_currentPass == 0)
				visitExploreForEvents(scene);
			else
				visitBuildRenderStates(scene);
			
			++_numNodes;
		}
		
		protected function visitExploreForEvents(scene : IScene) : void
		{
			var actions 	: Vector.<IAction> 	= scene.actions;
			var numActions	: int				= actions.length;
			var	action 		: IAction			= null;
			
			if (scene is PickableGroup)
			{
				var pickableGroup : PickableGroup = scene as PickableGroup;
				
				_subscribedEvents |= pickableGroup.subscribedEvents;
			}
			
			for (var i : int = 0; i < numActions; ++i)
			{
				action = actions[i];
				
				if (action.type & ACTION_TYPES_EXPLORE_PASS)
					action.run(scene, this, _renderer);
			}
		}
		
		protected function visitBuildRenderStates(scene : IScene) : void
		{
			var actions 	: Vector.<IAction> 	= scene.actions;
			var numActions	: int				= actions.length;
			var action		: IAction			= null;
			
			if (scene is PickableGroup)
			{
				var pickableGroup : PickableGroup = scene as PickableGroup;
				
				_pickingSceneNodes.push(scene);
				_currentColor += COLOR_INCREMENT;
				
				_renderingData.styleStack.set(PickingStyle.CURRENT_COLOR, _currentColor);
				
				_subscribedEvents |= pickableGroup.subscribedEvents;
			}
			
			for (var i : int = 0; i < numActions; ++i)
			{
				action = actions[i];
				
				if (action.type == ActionType.RENDER)
					PICKING_RENDER_ACTION.run(scene, this, _renderer)
				else if (action.type & ACTION_TYPES_RENDER_PASS)
					action.run(scene, this, _renderer);
			}
		}
	}
}
