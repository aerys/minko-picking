package aerys.minko.effect
{
	import aerys.minko.render.shader.SFloat;
	import aerys.minko.render.shader.Shader;
	import aerys.minko.render.shader.ShaderSettings;
	import aerys.minko.render.shader.part.animation.VertexAnimationShaderPart;
	
	public final class PickingShader extends Shader
	{
		private var _vertexAnimation	: VertexAnimationShaderPart	= null;
		
		public function PickingShader()
		{
			super();
			
			_vertexAnimation = new VertexAnimationShaderPart(this);
		}
		
		override protected function initializeSettings(settings : ShaderSettings) : void
		{
			settings.priority = Number.MAX_VALUE;
		}
		
		override protected function getVertexPosition() : SFloat
		{
			return localToScreen(
				_vertexAnimation.getAnimatedVertexPosition()
			);
		}
		
		override protected function getPixelColor() : SFloat
		{
			return float4(meshBindings.getParameter("picking id", 3), 1);
		}
	}
}