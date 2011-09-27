package aerys.minko.render.effect.picking
{
	import aerys.minko.render.RenderTarget;
	import aerys.minko.render.effect.IEffect;
	import aerys.minko.render.effect.IEffectPass;
	import aerys.minko.render.effect.SinglePassEffect;
	import aerys.minko.render.effect.basic.BasicStyle;
	import aerys.minko.render.renderer.RendererState;
	import aerys.minko.render.shader.Shader;
	import aerys.minko.render.shader.node.INode;
	import aerys.minko.render.shader.node.common.ClipspacePosition;
	import aerys.minko.render.shader.node.leaf.Constant;
	import aerys.minko.render.shader.node.leaf.StyleParameter;
	import aerys.minko.render.shader.node.operation.manipulation.Combine;
	import aerys.minko.scene.data.StyleData;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.scene.data.ViewportData;
	import aerys.minko.type.enum.Blending;
	import aerys.minko.type.enum.TriangleCulling;
	
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	public class PickingEffect extends SinglePassEffect implements IEffect, IEffectPass
	{
		protected static const TARGET		: RenderTarget	= new RenderTarget(RenderTarget.BACKBUFFER, 0, 0, 0);
		protected static const SHADER 		: PickingShader = new PickingShader();
		protected static const RECTANGLE 	: Rectangle 	= new Rectangle(0, 0, 10, 10);
		
		public function PickingEffect(priority		: Number		= 0,
									  renderTarget	: RenderTarget	= null)
		{
			super(SHADER, priority, renderTarget);
		}
		override public function fillRenderState(state			: RendererState,
												 styleData		: StyleData, 
												 transformData	: TransformData, 
												 worldData		: Dictionary) : Boolean
		{
			super.fillRenderState(state, styleData, transformData, worldData);
			
			var currentColor		: uint		= styleData.get(PickingStyle.CURRENT_COLOR, 0) as uint;
			var isOcludingObject	: Boolean	= styleData.get(PickingStyle.OCLUDER, true);
			var scissorRectangle	: Rectangle	= styleData.get(PickingStyle.RECTANGLE, 0) as Rectangle;
			
			if (!isOcludingObject && currentColor == 0)
				return false;
			
			state.blending			= Blending.NORMAL;
			state.rectangle			= scissorRectangle;
			
			return true;
		}
	}
}