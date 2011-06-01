package aerys.minko.render.visitor
{
	import aerys.minko.render.IRenderer3D;
	import aerys.minko.render.state.RenderStatesManager;
	import aerys.minko.render.state.WriteMask;
	import aerys.minko.scene.IPickable3D;
	import aerys.minko.scene.IScene3D;
	
	import flash.geom.Point;
	import aerys.minko.query.IScene3DVisitor;
	import aerys.minko.query.Scene3DVisitorModifier;
	
	public class PickingVisitor3D extends Scene3DVisitorModifier
	{
		private var _pickable	: Vector.<IPickable3D>	= new Vector.<IPickable3D>();
		//private var _renderer	: PickingRenderer3D		= new PickingRenderer3D();
		private var _picking	: uint					= 0;
		private var _drawing	: Boolean				= true;
		private var _mask		: uint					= 0;
		private var _precision	: Number				= 0;
		
		public function get picking() : uint	{ return _picking; }
		
		public function getSceneUnderPoint(x : Number, y : Number) : IPickable3D
		{
			/*var id : int = _renderer.pickId(x, (y < 0. ? 0. : y) + 1);
			
			return id < 0 ? null : _pickable[id];*/
			
			return null;
		}
		
		public function PickingVisitor3D()
		{
			super();
		}
		
		override public function get renderer() : IRenderer3D
		{
			return null;
		}
		
		override public function visit(scene 	: IScene3D,
									   visitor 	: IScene3DVisitor = null) : void
		{
			/*var states		: RenderStatesManager	= _drawing ? _renderer.states : null;
			var pickable	: IPickable3D			= scene as IPickable3D;
			var picked		: Boolean				= _drawing && pickable && (pickable.picking & _mask)
			
			if (picked)
				states.writeMask = WriteMask.COLOR_RGB | WriteMask.DEPTH;
							
			super.visit(scene);
			
			if (picked)
				states.writeMask = WriteMask.DEPTH;
			
			if (pickable)
			{
				_picking |= pickable.picking;
				if (picked)
					_pickable[_renderer.currentId] = pickable;
			}*/
		}
		
		public function startPicking(precision		: Number,
									 target 		: IScene3DVisitor,
									 pickingMask 	: uint,
									 max			: Point,
									 min			: Point) : void
		{
			_precision = precision;
			this.target = target;
			_mask = pickingMask;
			
			/*_pickable.length = 0;
			_renderer.target = target.renderer;
			_renderer.begin(_precision, max, min);*/
		}
		
		public function stopPicking() : void
		{
			//_renderer.end();
		}
		
		public function startFetchingPicking() : void
		{
			_drawing = false;
			_picking = 0;
		}
		
		public function stopFetchingPicking() : uint
		{
			_drawing = true;
			
			return _picking;
		}
	}
}