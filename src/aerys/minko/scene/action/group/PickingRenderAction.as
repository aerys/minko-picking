package aerys.minko.scene.action.group
{
	import aerys.minko.render.effect.IEffectPass;
	import aerys.minko.render.effect.picking.PickingEffect;
	import aerys.minko.render.renderer.IRenderer;
	import aerys.minko.render.renderer.state.RenderState;
	import aerys.minko.scene.action.ActionType;
	import aerys.minko.scene.action.IAction;
	import aerys.minko.scene.node.IScene;
	import aerys.minko.scene.node.mesh.IMesh;
	import aerys.minko.scene.visitor.ISceneVisitor;
	import aerys.minko.scene.visitor.data.IWorldData;
	import aerys.minko.scene.visitor.data.LocalData;
	import aerys.minko.scene.visitor.data.RenderingData;
	import aerys.minko.type.stream.IndexStream;
	import aerys.minko.type.stream.VertexStreamList;
	
	import flash.utils.Dictionary;
	
	public class PickingRenderAction implements IAction
	{
		protected static const PICKING_EFFECT_PASS : PickingEffect = new PickingEffect();
		
		public function get type() : uint
		{
			throw new Error('This is a custom action that must be called only by Picking visitors');
		}
		
		public function prefix(scene	: IScene, 
							   visitor	: ISceneVisitor, 
							   renderer	: IRenderer) : Boolean
		{
			return true;
		}
		
		public function infix(scene : IScene, visitor : ISceneVisitor, renderer : IRenderer) : Boolean
		{
			var mesh : IMesh	= scene as IMesh;
			
			if (!mesh)
				throw new Error();
			
			// invalidate world objects cache
			for each (var worldObject : IWorldData in visitor.worldData)
				worldObject.invalidate();
			
			// pass "ready to draw" data to the renderer.
			var localData			: LocalData			= visitor.localData;
			var worldData			: Dictionary		= visitor.worldData;
			var renderingData		: RenderingData		= visitor.renderingData;
			var vertexStreamList 	: VertexStreamList	= mesh.vertexStreamList;
			var indexStream 		: IndexStream		= mesh.indexStream;
			
			renderer.begin();
			
			var state	: RenderState = renderer.state;
			
			if (PICKING_EFFECT_PASS.fillRenderState(state, renderingData.styleStack, localData, worldData))
			{
				state.setInputStreams(vertexStreamList, indexStream);
				renderer.drawTriangles();
			}
			
			renderer.end();
			
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