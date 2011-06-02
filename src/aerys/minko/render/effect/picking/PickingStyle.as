package aerys.minko.render.effect.picking
{
	import aerys.minko.scene.visitor.data.Style;

	public final class PickingStyle
	{
		public static const OCLUDER			: int = Style.getStyleId('pickingOcluder');
		public static const CURRENT_COLOR	: int = Style.getStyleId('pickingCurrentColor');
		public static const RECTANGLE		: int = Style.getStyleId('pickingRectangle');
	}
}