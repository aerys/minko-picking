package aerys.minko.render.effect.picking
{
	import aerys.minko.render.shader.ActionScriptShader;
	import aerys.minko.render.shader.SValue;
	
	public class PickingShader extends ActionScriptShader
	{
		override protected function getOutputPosition() : SValue
		{
			return vertexClipspacePosition;
		}
		
		override protected function getOutputColor() : SValue
		{
			return float4(getStyleParameter(3, PickingStyle.CURRENT_COLOR), 1.);
		}
	}
}