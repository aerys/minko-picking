package aerys.minko.render.effect.picking
{
	import aerys.minko.render.RenderTarget;
	import aerys.minko.render.effect.IEffect;
	import aerys.minko.render.effect.IEffectPass;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.renderer.state.Blending;
	import aerys.minko.render.renderer.state.RendererState;
	import aerys.minko.render.renderer.state.TriangleCulling;
	import aerys.minko.render.shader.Shader;
	import aerys.minko.render.shader.node.INode;
	import aerys.minko.render.shader.node.common.ClipspacePosition;
	import aerys.minko.render.shader.node.leaf.Constant;
	import aerys.minko.render.shader.node.leaf.StyleParameter;
	import aerys.minko.render.shader.node.operation.manipulation.Combine;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.scene.data.StyleStack;
	import aerys.minko.scene.data.ViewportData;
	
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	public class PickingEffect implements IEffect, IEffectPass
	{
		protected static const TARGET			: RenderTarget	= new RenderTarget(RenderTarget.BACKBUFFER, 0, 0, 0);
		protected static const POSITION_NODE	: INode 		= new ClipspacePosition();
		protected static const COLOR_NODE		: INode			= new Combine(
			new StyleParameter(3, PickingStyle.CURRENT_COLOR),
			new Constant(1)
		);
		protected static const SHADER : Shader = Shader.create(POSITION_NODE, COLOR_NODE);
		
		protected static const RECTANGLE : Rectangle = new Rectangle(0, 0, 10, 10);
		
		protected var _passes		: Vector.<IEffectPass>;
		protected var _priority		: Number;
		protected var _renderTarget	: RenderTarget;
		
		public function PickingEffect(priority		: Number		= 0,
									  renderTarget	: RenderTarget	= null)
		{
			_passes = new Vector.<IEffectPass>(1, true);
			_passes[0] = this;
			
			_priority = priority;
			_renderTarget = TARGET;
		}
		
		public function getPasses(styleStack	: StyleStack, 
								  local			: TransformData, 
								  world			: Dictionary) : Vector.<IEffectPass>
		{
			return _passes;
		}
		
		public function fillRenderState(state		: RendererState,
										styleStack	: StyleStack, 
										local		: TransformData, 
										world		: Dictionary) : Boolean
		{
			var currentColor		: uint		= styleStack.get(PickingStyle.CURRENT_COLOR, 0) as uint;
			var isOcludingObject	: Boolean	= styleStack.get(PickingStyle.OCLUDER, true);
			var scissorRectangle	: Rectangle	= styleStack.get(PickingStyle.RECTANGLE, 0) as Rectangle;
			
			if (!isOcludingObject && currentColor == 0)
				return false;
			
			SHADER.fillRenderState(state, styleStack, local, world);
			
			state.blending			= Blending.NORMAL;
			state.priority			= _priority;
			state.rectangle			= scissorRectangle;
			state.renderTarget		= _renderTarget || world[ViewportData].renderTarget;
			state.triangleCulling	= styleStack.get(BasicStyle.TRIANGLE_CULLING, TriangleCulling.BACK) as uint;
			
			return true;
		}
	}
}