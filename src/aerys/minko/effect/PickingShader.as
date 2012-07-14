package aerys.minko.effect
{
	import aerys.minko.render.effect.basic.BasicShader;
	import aerys.minko.render.shader.SFloat;
	import aerys.minko.render.shader.ShaderSettings;
	
	public final class PickingShader extends BasicShader
	{
		override protected function initializeSettings(settings : ShaderSettings) : void
		{
			super.initializeSettings(settings);
			
			settings.priority = Number.MAX_VALUE;
//			settings.enabled = meshBindings.propertyExists('pickingId');
		}
		
		override protected function getPixelColor() : SFloat
		{
			return float4(meshBindings.getParameter('pickingId', 3), 1);
		}
	}
}