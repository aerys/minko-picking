package aerys.minko.scene.visitor
{
	import aerys.minko.render.Viewport;
	import aerys.minko.scene.data.ViewportData;
	
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class VMousePickingVisitor extends PickingVisitor
	{
		private static var TMP_POINT : Point = new Point();
		
		public function VMousePickingVisitor(refreshRate : uint = 1)
		{
			super(refreshRate);
		}
		
		override protected function configure() : void
		{
			_waitingForDispatchEvents &= ~EVENT_MOUSE_MOVE;
			super.configure();
		}
		
		override protected function onStageMouseMove(e : MouseEvent) : void
		{
			super.onStageMouseMove(e);
			
			var viewportData	: ViewportData	= _worldData[ViewportData];
			var viewport		: Viewport		= viewportData.viewport;
			
			TMP_POINT.x = e.stageX;
			TMP_POINT.y = e.stageY;
			TMP_POINT = viewport.globalToLocal(TMP_POINT);
			
			_viewportX = TMP_POINT.x;
			_viewportY = TMP_POINT.y;
		}
	}
}
