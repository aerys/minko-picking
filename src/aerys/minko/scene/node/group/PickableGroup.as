package aerys.minko.scene.node.group
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;
	
	public class PickableGroup extends Group implements IEventDispatcher
	{
		protected static const EVENT_CLICK			: uint = 1 << 0;
		protected static const EVENT_DOUBLE_CLICK	: uint = 1 << 1;
		protected static const EVENT_MOUSE_DOWN		: uint = 1 << 2;
		protected static const EVENT_MOUSE_MOVE		: uint = 1 << 3;
		protected static const EVENT_MOUSE_OUT		: uint = 1 << 4;
		protected static const EVENT_MOUSE_OVER		: uint = 1 << 5;
		protected static const EVENT_MOUSE_UP		: uint = 1 << 6;
		protected static const EVENT_MOUSE_WHEEL	: uint = 1 << 7;
		protected static const EVENT_ROLL_OVER		: uint = 1 << 8;
		protected static const EVENT_ROLL_OUT		: uint = 1 << 9;
		
		protected static var _eventsToMask			: Object = null;
		
		protected var _dispatcher		: IEventDispatcher;
		protected var _useHandCursor	: Boolean;
		protected var _subscribedEvents	: uint;
		
		public function get subscribedEvents() : uint
		{
			return _subscribedEvents;
		}
		
		public function get useHandCursor() : Boolean
		{
			return _useHandCursor;
		}
		
		public function set useHandCursor(v : Boolean) : void
		{
			_useHandCursor = v;
			
			if (useHandCursor)
			{
				_subscribedEvents |= _eventsToMask[MouseEvent.MOUSE_OVER];
			}	
			else if (!useHandCursor && !_dispatcher.hasEventListener(MouseEvent.MOUSE_OVER))
			{
				_subscribedEvents &= ~_eventsToMask[MouseEvent.MOUSE_OVER];
			}
		}
		
		public function PickableGroup(...children)
		{
			super(children);
			
			_dispatcher			= new EventDispatcher(this);
			_subscribedEvents	= 0;
			
			if (_eventsToMask == null)
			{
				_eventsToMask							= new Object();
				_eventsToMask[MouseEvent.CLICK]			= EVENT_CLICK;
				_eventsToMask[MouseEvent.DOUBLE_CLICK]	= EVENT_DOUBLE_CLICK;
				_eventsToMask[MouseEvent.MOUSE_DOWN]	= EVENT_MOUSE_DOWN;
				_eventsToMask[MouseEvent.MOUSE_MOVE]	= EVENT_MOUSE_MOVE;
				_eventsToMask[MouseEvent.MOUSE_OUT]		= EVENT_MOUSE_OUT;
				_eventsToMask[MouseEvent.MOUSE_OVER]	= EVENT_MOUSE_OVER;
				_eventsToMask[MouseEvent.MOUSE_UP]		= EVENT_MOUSE_UP;
				_eventsToMask[MouseEvent.MOUSE_WHEEL]	= EVENT_MOUSE_WHEEL;
				_eventsToMask[MouseEvent.ROLL_OVER]		= EVENT_ROLL_OVER;
				_eventsToMask[MouseEvent.ROLL_OUT]		= EVENT_ROLL_OUT;
			}
		}
		
		public function addEventListener(type 				: String,
										 listener			: Function,
										 useCapture			: Boolean	= false,
										 priority			: int		= 0,
										 useWeakReference	: Boolean	= false) : void
		{
			_subscribedEvents |= _eventsToMask[type];
			
			_dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type		: String,
											listener	: Function,
											useCapture	: Boolean	= false) : void
		{
			_dispatcher.removeEventListener(type, listener, useCapture);
			
			if (!_dispatcher.hasEventListener(type) // verifie ca
				&& (type != MouseEvent.MOUSE_OVER || !_useHandCursor))
				_subscribedEvents &= ~_eventsToMask[type];
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