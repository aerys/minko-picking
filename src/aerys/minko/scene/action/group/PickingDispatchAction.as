package aerys.minko.scene.action.group
{
	import aerys.minko.render.renderer.IRenderer;
	import aerys.minko.scene.action.IAction;
	import aerys.minko.scene.node.IScene;
	import aerys.minko.scene.visitor.ISceneVisitor;
	
	public class PickingDispatchAction implements IAction
	{
		public function get type():uint
		{
			throw new Error('This is a custom action that must be called only by Picking visitors');
		}
		
		public function prefix(scene	: IScene, 
							   visitor	: ISceneVisitor, 
							   renderer	: IRenderer) : Boolean
		{
			return true;
		}
		
		public function infix(scene		: IScene, 
							  visitor	: ISceneVisitor, 
							  renderer	: IRenderer) : Boolean
		{
			return true;
		}
		
		public function postfix(scene		: IScene, 
								visitor		: ISceneVisitor, 
								renderer	: IRenderer) : Boolean
		{
			return true;
		}
	}
}