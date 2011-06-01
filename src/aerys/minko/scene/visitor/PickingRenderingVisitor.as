package aerys.minko.scene.visitor
{
	import aerys.minko.render.renderer.IRenderer;
	import aerys.minko.scene.action.ActionType;
	import aerys.minko.scene.action.IAction;
	import aerys.minko.scene.action.group.PickingRenderAction;
	import aerys.minko.scene.node.IScene;
	import aerys.minko.scene.visitor.data.LocalData;
	import aerys.minko.scene.visitor.data.RenderingData;
	
	import flash.utils.Dictionary;
	
	public class PickingRenderingVisitor implements ISceneVisitor
	{
		protected static const ACTION_TYPES				: uint		= ActionType.RECURSE | ActionType.UPDATE_LOCAL_DATA;
		protected static const PICKING_RENDER_ACTION	: IAction	= new PickingRenderAction();
		
		protected var _localData 		: LocalData;
		protected var _worldData 		: Dictionary;
		protected var _renderingData	: RenderingData
		protected var _renderer			: IRenderer;
		
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
			return null;
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
			
			visit(scene);
		}
		
		public function visit(scene : IScene) : void
		{
			var actions 	: Vector.<IAction> 	= scene.actions;
			var numActions	: int				= actions.length;
			
			var	i : int, action : IAction, actionType : uint;
			
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
