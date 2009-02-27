package com.gorillalogic.security
{
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.utils.DescribeTypeCache;
	
	//
	// Chimp filters UI components based on metadata with in UIComponenets
	//
	public class Chimp {
		
		private static var _permissions:ArrayCollection;
		
		/**
		 * Load chimp before the UIComponents are added with permission strings
		 */
		public static function load(permissions:ArrayCollection):void {
			_permissions = permissions;
		
			//add chmip system add handler	
			Application.application.systemManager.addEventListener(Event.ADDED_TO_STAGE, processComponenet, true);
		}

		/**
		 * Unload chimp
		 */
		public static function unload():void {
			Application.application.systemManager.removeEventListener(Event.ADDED_TO_STAGE, processComponenet);
		}
		
		//event for processing when component is added
		private static function processComponenet(event:Event):void {
			process(event.target);
		}

		//process ui object
		private static function process(obj:Object):void {
			var typeInfo:XML = DescribeTypeCache.describeType(obj).typeDescription;
			var md:XMLList = typeInfo.metadata.(@name == ChimpConstants.PROTECTED_ANNOTATION_NAME);
			for each (var metadata:XML in md) {
				var chimpAction:ChimpAction = getAction(metadata);
				var comp:UIComponent = obj as UIComponent;
				
				if(chimpAction.componentId == null || 
						chimpAction.componentId == "" || chimpAction.componentId == ChimpConstants.PARENT_STRING) { //process protections for parent
					chimpAction.comp = comp;
					doAction(chimpAction);
				} else {
					if(comp.getChildByName(chimpAction.componentId) == null) { // child comp has not been created yet 					
						comp.addEventListener(FlexEvent.CREATION_COMPLETE, processComponenet); //add event to process later
					} else { //process child component
						chimpAction.comp = comp.getChildByName(chimpAction.componentId) as UIComponent;
						doAction(chimpAction);
					}
				}
			}
		}
		
		//create action from meta data
		private static function getAction(protectedMetadata:XML):ChimpAction {
			var chimpAction:ChimpAction = new ChimpAction();
			chimpAction.permissions = protectedMetadata..arg.(@key == "permissions").@value;
			chimpAction.inPermissionAction = protectedMetadata..arg.(@key == "inPermissionAction").@value;
			chimpAction.notInPermissionAction = protectedMetadata..arg.(@key == "notInPermissionAction").@value;
			chimpAction.componentId = protectedMetadata..arg.(@key == "componentId").@value;
			return chimpAction;
		}
		
		//process action
		private static function doAction(chimpAction:ChimpAction):void {
			var stringAction:String = null; 
			if(chimpAction.notInPermissionAction != null && !isPermPresent(chimpAction.permissions)) {
				stringAction = chimpAction.notInPermissionAction;
			} else if(chimpAction.inPermissionAction != null && isPermPresent(chimpAction.permissions)) {
				stringAction = chimpAction.inPermissionAction;
			}
			
			if(stringAction != null) {
				if (stringAction == ChimpConstants.ACTION_REMOVE) {
					chimpAction.comp.parent.removeChild(chimpAction.comp);
				} else if (stringAction == ChimpConstants.ACTION_INVISABLE) {
					chimpAction.comp.visible = false;				
				} else if (stringAction == ChimpConstants.ACTION_DISABLE) {
					chimpAction.comp.enabled = false;	
				} else if (stringAction == ChimpConstants.ACTION_VISABLE) {
					chimpAction.comp.visible = true;				
				} else if (stringAction == ChimpConstants.ACTION_ENABLE) {
					chimpAction.comp.enabled = true;	
				}	
			}		
		}

		//check for permissions
		private static function isPermPresent(allowedPerms:String):Boolean {
			var asdf:ArrayCollection = _permissions;
			if(allowedPerms != null) {
				for each(var perm:String in _permissions) {
					if(allowedPerms.indexOf(perm) >= 0)
						return true;
				}
			}
			return false;
		}
	}
}
