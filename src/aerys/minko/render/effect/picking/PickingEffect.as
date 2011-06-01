package aerys.minko.render.effect.picking
{
	import aerys.minko.render.RenderTarget;
	import aerys.minko.render.effect.IEffect;
	import aerys.minko.render.effect.IEffectPass;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.renderer.state.Blending;
	import aerys.minko.render.renderer.state.RenderState;
	import aerys.minko.render.renderer.state.TriangleCulling;
	import aerys.minko.render.shader.DynamicShader;
	import aerys.minko.render.shader.node.common.ClipspacePosition;
	import aerys.minko.render.shader.node.picking.PickingNode;
	import aerys.minko.scene.visitor.data.LocalData;
	import aerys.minko.scene.visitor.data.StyleStack;
	import aerys.minko.scene.visitor.data.ViewportData;
	
	import flash.utils.Dictionary;
	
	public class PickingEffect implements IEffect, IEffectPass
	{
		protected static const SHADER : DynamicShader = 
			DynamicShader.create(new ClipspacePosition(), new PickingNode());
		
		protected var _passes		: Vector.<IEffectPass>;
		protected var _priority		: Number;
		protected var _renderTarget	: RenderTarget;
		
		public function PickingEffect(priority		: Number		= 0,
									  renderTarget	: RenderTarget	= null)
		{
			_passes = new Vector.<IEffectPass>(1, true);
			_passes[0] = this;
		}
		
		public function getPasses(styleStack	: StyleStack, 
								  local			: LocalData, 
								  world			: Dictionary) : Vector.<IEffectPass>
		{
			return _passes;
		}
		
		public function fillRenderState(state		: RenderState,
										styleStack	: StyleStack, 
										local		: LocalData, 
										world		: Dictionary) : Boolean
		{
			if (styleStack.get(PickingStyle.OCLUDER, false))
				return false;
			
			SHADER.fillRenderState(state, styleStack, local, world);
			
			state.blending			= Blending.NORMAL;
			state.priority			= _priority;
			state.renderTarget		= _renderTarget || world[ViewportData].renderTarget;
			state.triangleCulling	= styleStack.get(BasicStyle.TRIANGLE_CULLING, TriangleCulling.BACK) as uint;
			
			return true;
		}
		
	}
}