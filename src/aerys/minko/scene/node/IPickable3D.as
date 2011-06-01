package aerys.minko.scene.node
{
	
	import flash.events.IEventDispatcher;
	
	public interface IPickable3D extends IEventDispatcher, IScene
	{
		function get picking() : uint;
	}
}