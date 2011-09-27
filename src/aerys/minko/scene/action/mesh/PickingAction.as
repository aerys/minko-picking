package aerys.minko.scene.action.mesh
{
	import aerys.minko.render.effect.picking.PickingEffect;
	import aerys.minko.render.renderer.IRenderer;
	import aerys.minko.render.renderer.RendererState;
	import aerys.minko.scene.action.IAction;
	import aerys.minko.scene.data.IWorldData;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.scene.data.RenderingData;
	import aerys.minko.scene.node.IScene;
	import aerys.minko.scene.node.mesh.IMesh;
	import aerys.minko.scene.visitor.ISceneVisitor;
	import aerys.minko.type.stream.IVertexStream;
	
	import flash.utils.Dictionary;
	
	public class PickingAction implements IAction
	{
		protected static const PICKING_EFFECT_PASS : PickingEffect = new PickingEffect();
		
		public function get type() : uint
		{
			throw new Error('This is a custom action that must be called only by Picking visitors');
		}
		
		public function run(scene		: IScene,
							visitor		: ISceneVisitor, 
							renderer	: IRenderer) : Boolean
		{
			var mesh : IMesh	= scene as IMesh;
			
			if (!mesh)
				throw new Error('This action should be called only on meshes');
			
			// invalidate world objects cache
			for each (var worldObject : IWorldData in visitor.worldData)
				worldObject.invalidate();
			
			// pass "ready to draw" data to the renderer.
			var transformData	: TransformData				= visitor.transformData;
			var worldData		: Dictionary				= visitor.worldData;
			var renderingData	: RenderingData				= visitor.renderingData;
			var state			: RendererState 			= RendererState.create(true);
			
			if (PICKING_EFFECT_PASS.fillRenderState(state, renderingData.styleStack, transformData, worldData))
			{
				state.setVertexStreamAt(mesh.vertexStream, 0);
				state.indexStream = mesh.indexStream;
				
				renderer.pushState(state);
				renderer.drawTriangles();
			}
			
			return true;
		}
	}
}