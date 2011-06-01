package aerys.minko.scene.group
{
	import aerys.minko.enum.Picking;
	import aerys.minko.event.Mouse3DEvent;
	import aerys.minko.Viewport3D;
	import aerys.minko.render.IRenderer3D;
	import aerys.minko.render.state.RenderState;
	import aerys.minko.render.state.RenderStatesManager;
	import aerys.minko.render.state.WriteMask;
	import aerys.minko.query.IScene3DVisitor;
	import aerys.minko.render.visitor.PickingVisitor3D;
	import aerys.minko.scene.IPickable3D;
	
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.getTimer;
	
	public class PickingGroup3D extends Group3D
	{
		public static const DEFAULT_PRECISION		: Number	= .25;
		public static const DEFAULT_FRAMERATE_RATIO	: Number	= .15;
		
		private static const MOVE_PICKING_FLAGS	: uint		= Picking.MOUSE_MOVE
															  | Picking.ROLL_OUT
															  | Picking.ROLL_OVER;
		
		private var _initialized	: Boolean				= false;
		private var _pendingPicking	: uint					= 0;
		private var _picking		: uint					= 0;
		private var _visitor		: PickingVisitor3D		= new PickingVisitor3D();
		
		private var _lastOver		: IPickable3D			= null;
		
		private var _events			: Vector.<MouseEvent>	= new Vector.<MouseEvent>();
		private var _flags			: Vector.<uint>			= new Vector.<uint>();
		private var _numEvents		: int					= 0;
		
		private var _max			: Point					= new Point(Number.NEGATIVE_INFINITY, Number.NEGATIVE_INFINITY);
		private var _min			: Point					= new Point(Number.POSITIVE_INFINITY, Number.POSITIVE_INFINITY);
		//private var _debug			: Shape					= new Shape();
		
		private var _stageX			: Number				= 0.;
		private var _stageY			: Number				= 0.;
		
		private var _precision		: Number				= .25;
		private var _framerateRatio	: Number				= .25;
		
		private var _lastVisit		: int					= 0;
		
		public function PickingGroup3D(precision 		: Number 	= DEFAULT_PRECISION,
									   framerateRatio	: Number	= DEFAULT_FRAMERATE_RATIO,
									   ...children)
		{
			super(children);
			
			name = "PickingGroup3D";
			_precision = Math.min(1., Math.max(0., precision));
			_framerateRatio = Math.min(1., Math.max(0., framerateRatio));
		}
		
		override public function accept(visitor : IScene3DVisitor) : void
		{
			if (numChildren == 0)
				return ;
			
			var renderer	: IRenderer3D			= visitor.renderer;
			var states 		: RenderStatesManager 	= renderer.states;
			var vp		 	: Viewport3D 			= renderer.viewport;

			// update listened events if necessary
			if (_picking == 0)
			{
				_visitor.target = visitor;
				_visitor.startFetchingPicking();
				
				super.query(_visitor);
				
				_picking = _visitor.stopFetchingPicking();
			}
			
			// initialize listeners
			if (!_initialized)
			{
				_initialized = true;
				
				vp.stage.addEventListener(MouseEvent.CLICK, mouseClickHandler);
				vp.stage.addEventListener(MouseEvent.DOUBLE_CLICK, mouseDoubleClickHandler);
				vp.stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveHandler);
				vp.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
				vp.stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
				
				//vp.addChild(_debug);
			}
			
			/*_debug.graphics.clear();
			_debug.graphics.beginFill(0xff0000, .25);
			_debug.graphics.drawRect(_min.x, _min.y, _max.x - _min.x, _max.y - _min.y);*/
			
			var time : int = getTimer();
			
			if (time - _lastVisit >= (1000. / vp.stage.frameRate) / _framerateRatio)
			{
				if ((_picking & _pendingPicking) || (_picking & MOVE_PICKING_FLAGS))
				{
					_visitor.startPicking(_precision,
										  visitor,
										  _pendingPicking | (_picking & MOVE_PICKING_FLAGS),
										  _max, _min);
					super.query(_visitor);
					_visitor.stopPicking();
					_picking = _visitor.picking;
					
					// dispatch pending events
					if (_picking & MOVE_PICKING_FLAGS)
						pick(MOVE_PICKING_FLAGS, _stageX, _stageY);
					
					for (var i : int = 0; i < _numEvents; i++)
					{
						var event	: MouseEvent 	= _events[i];
						
						pick(_flags[i], event.stageX, event.stageY);
					}
				}
				
				_lastVisit = time;
				_pendingPicking = 0;
				_events.length = 0;
				_numEvents = 0;
				_max.x = _max.y = Number.NEGATIVE_INFINITY;
				_min.x = _min.y = Number.POSITIVE_INFINITY;
			}
		}
		
		private function pick(mask : uint, x : Number, y : Number) : void
		{
			var picked 	: IPickable3D 	= _visitor.getSceneUnderPoint(x, y);
			
			if (_lastOver && (_lastOver.picking & Picking.ROLL_OUT) && picked != _lastOver)
				_lastOver.dispatchEvent(new Mouse3DEvent(Mouse3DEvent.ROLL_OUT));
			
			if (picked)
			{
				var picking : uint = mask & picked.picking;
				
				if (picking & Picking.CLICK)
					picked.dispatchEvent(new Mouse3DEvent(Mouse3DEvent.CLICK));
				if (picking & Picking.DOUBLE_CLICK)
					picked.dispatchEvent(new Mouse3DEvent(Mouse3DEvent.DOUBLE_CLICK));
				if (picking & Picking.MOUSE_DOWN)
					picked.dispatchEvent(new Mouse3DEvent(Mouse3DEvent.MOUSE_DOWN));
				if (picking & Picking.MOUSE_UP)
					picked.dispatchEvent(new Mouse3DEvent(Mouse3DEvent.MOUSE_UP));
				if (picking & Picking.MOUSE_MOVE)
					picked.dispatchEvent(new Mouse3DEvent(Mouse3DEvent.MOUSE_MOVE));
				if (picking & Picking.ROLL_OVER && _lastOver != picked)
					picked.dispatchEvent(new Mouse3DEvent(Mouse3DEvent.ROLL_OVER));
			}
			
			_lastOver = picked;
		}
		
		private function registerMouseEvent(pickingFlag : uint, event : MouseEvent) : void
		{
			if (_picking & pickingFlag)
			{
				_pendingPicking |= pickingFlag;
				_events[_numEvents] = event;
				_flags[_numEvents] = pickingFlag;
				++_numEvents;
				
				_max.x = event.stageX > _max.x ? event.stageX : _max.x;
				_max.y = event.stageY > _max.y ? event.stageY : _max.y;
				_min.x = event.stageX < _min.x ? event.stageX : _min.x;
				_min.y = event.stageY < _min.y ? event.stageY : _min.y;
			}
		}
		
		private function mouseDownHandler(event : MouseEvent) : void
		{
			registerMouseEvent(Picking.MOUSE_DOWN, event);
		}
		
		private function mouseUpHandler(event : MouseEvent) : void
		{
			registerMouseEvent(Picking.MOUSE_UP, event);
		}
		
		private function mouseClickHandler(event : MouseEvent) : void
		{
			registerMouseEvent(Picking.CLICK, event);
		}
		
		private function mouseDoubleClickHandler(event : MouseEvent) : void
		{
			registerMouseEvent(Picking.DOUBLE_CLICK, event);
		}
		
		private function mouseMoveHandler(event : MouseEvent) : void
		{
			registerMouseEvent(MOVE_PICKING_FLAGS, event);
			_stageX = event.stageX;
			_stageY = event.stageY;
		}
	}
}