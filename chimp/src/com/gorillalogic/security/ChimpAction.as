package com.gorillalogic.security
{
	import mx.core.UIComponent;
	
	public class ChimpAction
	{
		public function ChimpAction()
		{
		}
		
		public var comp:UIComponent;
		public var parentComp:UIComponent;
		public var childPosition:int;
		public var permissions:String;
		public var inPermissionAction:String;
		public var notInPermissionAction:String;
		public var componentId:String;

	}
}