package aerys.minko.scene.visitor
{
	import aerys.minko.render.renderer.IRenderer;
	import aerys.minko.scene.action.ActionType;
	import aerys.minko.scene.action.IAction;
	import aerys.minko.scene.node.IPickable3D;
	import aerys.minko.scene.node.IScene;
	import aerys.minko.scene.visitor.data.LocalData;
	import aerys.minko.scene.visitor.data.RenderingData;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	public class PickingDispatchVisitor implements ISceneVisitor
	{
		public static const ACTIONS_TYPES : uint = ActionType.RECURSE;
		
		protected var _localData	: LocalData;
		protected var _renderer		: IRenderer;
		
		public function get localData()		: LocalData		{ return _localData; }
		public function get worldData() 	: Dictionary	{ return null; }
		public function get renderingData()	: RenderingData	{ return null; }
		
		public function processSceneGraph(scene			: IScene, 
									 	  localData		: LocalData, 
									 	  worldData		: Dictionary, 
									 	  renderingData	: RenderingData,
									 	  renderer		: IRenderer) : void
		{
			_localData	= localData;
			_renderer	= renderer;
			
			visit(scene);
		}
		
		public function visit(scene : IScene) : void
		{
			var actions 	: Vector.<IAction> 	= scene.actions;
			var numActions	: int				= actions.length;
			var	i			: int				= 0;
			var action		: IAction			= null;
			
			for (i = 0; i < numActions; ++i)
				if (((action = actions[i]).type & ACTIONS_TYPES) && !action.prefix(scene, this, null))
					break ;
			
			for (i = 0; i < numActions; ++i)
				if (((action = actions[i]).type & ACTIONS_TYPES) && !action.infix(scene, this, null))
					break ;
			
			for (i = 0; i < numActions; ++i)
				if (((action = actions[i]).type & ACTIONS_TYPES) && !action.postfix(scene, this, null))
					break ;
		}
		
//		private var _pickable	: Vector.<IPickable3D>	= new Vector.<IPickable3D>();
//		//private var _renderer	: PickingRenderer3D		= new PickingRenderer3D();
//		private var _picking	: uint					= 0;
//		private var _drawing	: Boolean				= true;
//		private var _mask		: uint					= 0;
//		private var _precision	: Number				= 0;
//		
//		public function get picking() : uint	{ return _picking; }
//		
//		public function getSceneUnderPoint(x : Number, y : Number) : IPickable3D
//		{
//			/*var id : int = _renderer.pickId(x, (y < 0. ? 0. : y) + 1);
//			
//			return id < 0 ? null : _pickable[id];*/
//			
//			return null;
//		}
//		
//		public function PickingVisitor()
//		{
//			super();
//		}
//		
////		override public function get renderer() : IRenderer3D
////		{
////			return null;
////		}
//		
////		override public function visit(scene 	: IScene3D,
////									   visitor 	: IScene3DVisitor = null) : void
////		{
//			/*var states		: RenderStatesManager	= _drawing ? _renderer.states : null;
//			var pickable	: IPickable3D			= scene as IPickable3D;
//			var picked		: Boolean				= _drawing && pickable && (pickable.picking & _mask)
//			
//			if (picked)
//				states.writeMask = WriteMask.COLOR_RGB | WriteMask.DEPTH;
//							
//			super.visit(scene);
//			
//			if (picked)
//				states.writeMask = WriteMask.DEPTH;
//			
//			if (pickable)
//			{
//				_picking |= pickable.picking;
//				if (picked)
//					_pickable[_renderer.currentId] = pickable;
//			}*/
////		}
//		
//		public function startPicking(precision		: Number,
//									 target 		: ISceneVisitor,
//									 pickingMask 	: uint,
//									 max			: Point,
//									 min			: Point) : void
//		{
//			_precision = precision;
////			this.target = target;
//			_mask = pickingMask;
//			
//			/*_pickable.length = 0;
//			_renderer.target = target.renderer;
//			_renderer.begin(_precision, max, min);*/
//		}
//		
//		public function stopPicking() : void
//		{
//			//_renderer.end();
//		}
//		
//		public function startFetchingPicking() : void
//		{
//			_drawing = false;
//			_picking = 0;
//		}
//		
//		public function stopFetchingPicking() : uint
//		{
//			_drawing = true;
//			
//			return _picking;
//		}
	}
}