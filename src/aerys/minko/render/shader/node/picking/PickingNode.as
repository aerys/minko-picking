package aerys.minko.render.shader.node.picking
{
	import aerys.minko.render.effect.picking.PickingStyle;
	import aerys.minko.render.shader.node.Dummy;
	import aerys.minko.render.shader.node.INode;
	import aerys.minko.render.shader.node.leaf.StyleParameter;
	
	public class PickingNode extends Dummy
	{
		public function PickingNode()
		{
			super(new StyleParameter(4, PickingStyle.CURRENT_COLOR));
		}
	}
}