package aerys.minko.scene.group
{
	import aerys.minko.enum.Picking;
	import aerys.minko.event.Mouse3DEvent;
	import aerys.minko.scene.IPickable3D;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class PickableGroup3D extends Group3D implements IPickable3D
	{
		private var _dispatcher	: IEventDispatcher	= null;
		private var _picking	: uint				= 0;
		
		public function get picking() : uint		{ return _picking; }
		
		public function PickableGroup3D(...children)
		{
			super(children);
			
			_dispatcher = new EventDispatcher(this);
		}
		
		public function addEventListener(type 				: String,
										 listener			: Function,
										 useCapture			: Boolean	= false,
										 priority			: int		= 0,
										 useWeakReference	: Boolean	= false) : void
		{
			if (type == Mouse3DEvent.CLICK)
				_picking |= Picking.CLICK;
			else if (type == Mouse3DEvent.DOUBLE_CLICK)
				_picking |= Picking.DOUBLE_CLICK;
			else if (type == Mouse3DEvent.MOUSE_DOWN)
				_picking |= Picking.MOUSE_DOWN;
			else if (type == Mouse3DEvent.MOUSE_UP)
				_picking |= Picking.MOUSE_UP;
			else if (type == Mouse3DEvent.MOUSE_MOVE)
				_picking |= Picking.MOUSE_MOVE;
			else if (type == Mouse3DEvent.ROLL_OVER)
				_picking |= Picking.ROLL_OVER;
			else if (type == Mouse3DEvent.ROLL_OUT)
				_picking |= Picking.ROLL_OUT;
			
			_dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type		: String,
											listener	: Function,
											useCapture	: Boolean	= false) : void
		{
			_dispatcher.removeEventListener(type, listener, useCapture);
			
			if (!hasEventListener(type))
			{
				if (type == Mouse3DEvent.CLICK)
					_picking ^= Picking.CLICK;
				else if (type == Mouse3DEvent.DOUBLE_CLICK)
					_picking ^= Picking.DOUBLE_CLICK;
				else if (type == Mouse3DEvent.MOUSE_DOWN)
					_picking ^= Picking.MOUSE_DOWN;
				else if (type == Mouse3DEvent.MOUSE_UP)
					_picking ^= Picking.MOUSE_UP;
				else if (type == Mouse3DEvent.MOUSE_MOVE)
					_picking ^= Picking.MOUSE_MOVE;
				else if (type == Mouse3DEvent.ROLL_OVER)
					_picking ^= Picking.ROLL_OVER;
				else if (type == Mouse3DEvent.ROLL_OUT)
					_picking ^= Picking.ROLL_OUT;
			}
		}
		
		public function dispatchEvent(event	: Event) : Boolean
		{
			return _dispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type : String) : Boolean
		{
			return _dispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type : String) : Boolean
		{
			return _dispatcher.willTrigger(type);
		}
	}
}