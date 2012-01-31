package aerys.minko.render.effect.picking
{
	import aerys.minko.render.effect.SinglePassRenderingEffect;
	import aerys.minko.render.renderer.RendererState;
	import aerys.minko.render.target.AbstractRenderTarget;
	import aerys.minko.render.target.BackBufferRenderTarget;
	import aerys.minko.scene.data.StyleData;
	import aerys.minko.scene.data.TransformData;
	import aerys.minko.type.enum.Blending;
	
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	public class PickingEffect extends SinglePassRenderingEffect
	{
		protected static const TARGET		: BackBufferRenderTarget	= new BackBufferRenderTarget(0, 0, 0);
		protected static const SHADER 		: PickingShader 			= new PickingShader();
		protected static const RECTANGLE 	: Rectangle 				= new Rectangle(0, 0, 10, 10);
		
		public function PickingEffect()
		{
			super(SHADER, 0, TARGET);
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
			
			state.blending	= Blending.NORMAL;
			
			return true;
		}
	}
}