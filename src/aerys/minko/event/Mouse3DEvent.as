package aerys.minko.event
{
	import aerys.minko.scene.IScene3D;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	public final class Mouse3DEvent extends Event
	{
		public static const CLICK			: String	= "click3d";
		public static const DOUBLE_CLICK	: String	= "dclick3d";
		public static const MOUSE_DOWN		: String	= "down3d";
		public static const MOUSE_UP		: String	= "up3d";
		public static const MOUSE_MOVE		: String	= "move3d";
		public static const ROLL_OVER		: String	= "rollOver3d";
		public static const ROLL_OUT		: String	= "rollOut3d";
		
		public function Mouse3DEvent(type : String)
		{
			super(type);
		}
	}
}