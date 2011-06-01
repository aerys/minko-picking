package aerys.minko.scene.node.group
{
	import aerys.minko.scene.node.IPickable3D;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	public class PickableGroup extends Group implements IPickable3D
	{
		private var _dispatcher	: IEventDispatcher	= null;
		private var _picking	: uint				= 0;
		
		public function get picking() : uint		{ return _picking; }
		
		public function PickableGroup(...children)
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
			_dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type		: String,
											listener	: Function,
											useCapture	: Boolean	= false) : void
		{
			_dispatcher.removeEventListener(type, listener, useCapture);
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