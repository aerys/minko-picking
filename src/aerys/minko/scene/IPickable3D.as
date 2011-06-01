package aerys.minko.scene
{
	import flash.events.IEventDispatcher;
	
	public interface IPickable3D extends IEventDispatcher, IScene3D
	{
		function get picking() : uint;
	}
}