package com.gorillalogic.security
{
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.core.Application;
	import mx.core.UIComponent;
	import mx.events.CollectionEvent;
	import mx.utils.DescribeTypeCache;
	
	//
	// Chimp filters UI components based on metadata with in UIComponenets
	//
	public class Chimp {
		
		[Bindable] private static var _permissions:ArrayCollection;
		
		/**
		 * Load chimp before the UIComponents are added with permission strings
		 */
		public static function load(permissions:ArrayCollection):void {
			if(permissions != null) {
				_permissions = permissions;
				_permissions.addEventListener(CollectionEvent.COLLECTION_CHANGE, updateDisplay);
			} else {
				permissions = new ArrayCollection();
			}
			
			//add chmip system add handler	
			Application.application.systemManager.addEventListener(Event.ADDED_TO_STAGE, processComponenet, true);
		}
		
		
		/**
		 * Unloads chimp
		 */
		public static function unload():void {
			Application.application.systemManager.removeEventListener(Event.ADDED_TO_STAGE, processComponenet);
		}
				
		/**
		 * Overwrites perms with ArrayCollection
		 */
		public static function updatePerms(perms:ArrayCollection):void {
			_permissions = perms;
			_permissions.addEventListener(CollectionEvent.COLLECTION_CHANGE, updateDisplay);
			
			//update display
			updateDisplay(null);
		}

		/**
		 * Adds permissions to the chimp
		 */
		public static function addPerm(permName:String):void {
			_permissions.addItem(permName);
		}

		/**
		 * Removes permission from chimp
		 */
		public static function removePerm(permName:String):void {
			while(_permissions.contains(permName))
				_permissions.removeItemAt(_permissions.getItemIndex(permName));
		}
		
		//updates display on changes to the roles
		private static function updateDisplay(event:Event):void {
			for each(var chimpAction:ChimpAction in ChimpActionCache.instance.getAllActions()) {
				doAction(chimpAction);
			}
		}
		
		//event for processing when component is added
		private static function processComponenet(event:Event):void {
			process(event.target);
		}
		

		//process ui object
		private static function process(obj:Object):void {
			if(obj is UIComponent) {
				var comp:UIComponent = obj as UIComponent;
				var typeInfo:XML = DescribeTypeCache.describeType(obj).typeDescription;
				var md:XMLList = typeInfo.metadata.(@name == ChimpConstants.PROTECTED_ANNOTATION_NAME);
	
				//check for wating action
				if(comp.id != null && ChimpActionCache.instance.getDelayLoadHasId(comp.id)) { 
					for each(var delayedChimpAction:ChimpAction in ChimpActionCache.instance.getDelayLoadAction(comp)) {
						delayedChimpAction.comp = comp;
						doAction(delayedChimpAction);
						ChimpActionCache.instance.addAction(delayedChimpAction);							
					}
				} 
				
				for each (var metadata:XML in md) {
					var chimpAction:ChimpAction = getAction(metadata);
					
					if(chimpAction.componentId == null || 
							chimpAction.componentId == "" || chimpAction.componentId == ChimpConstants.PARENT_STRING) { //process protections for parent
						chimpAction.comp = comp;
						doAction(chimpAction);
						ChimpActionCache.instance.addAction(chimpAction);
					} else {
						if(comp.getChildByName(chimpAction.componentId) == null) { // child comp has not been created yet 										
							chimpAction.parentComp = comp;	
							ChimpActionCache.instance.addDelayLoadAction(chimpAction);	
						} else { //process child component
							chimpAction.comp = comp.getChildByName(chimpAction.componentId) as UIComponent;
							doAction(chimpAction);
							ChimpActionCache.instance.addAction(chimpAction);
						}
	
					}
				}
				
			//going to have to match on id and parentDocument
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
			//var stringAction:String = null; 
			var invert:Boolean = true;
			if(chimpAction.notInPermissionAction != null && chimpAction.notInPermissionAction.length > 0) {				
				if (!isPermPresent(chimpAction.permissions)) 
					invert = false
				runAction(chimpAction.notInPermissionAction, chimpAction, invert);
			} else if (chimpAction.inPermissionAction != null && chimpAction.inPermissionAction.length > 0) {
				if (isPermPresent(chimpAction.permissions))
					invert = false
				runAction(chimpAction.inPermissionAction, chimpAction, invert);					 
			}
		}
		
		//runs the action
		private static function runAction(stringAction:String, chimpAction:ChimpAction, invert:Boolean):void {
			if(stringAction != null) {
				if (stringAction == ChimpConstants.ACTION_REMOVE_CHILD) {
					if(invert) {
						if(chimpAction.parentComp != null && chimpAction.parentComp is UIComponent)
							chimpAction.parentComp.addChildAt(chimpAction.comp, chimpAction.childPosition);
					} else {
						if(chimpAction.comp.parent is UIComponent) {
							chimpAction.parentComp = chimpAction.comp.parent as UIComponent;
							chimpAction.childPosition = (chimpAction.comp.parent as UIComponent).getChildIndex(chimpAction.comp);
							(chimpAction.comp.parent as UIComponent).removeChild(chimpAction.comp);
						}
					}
				} else if (stringAction == ChimpConstants.ACTION_REMOVE_FROM_LAYOUT) {
					if(invert) {
						chimpAction.comp.includeInLayout = true;
					} else {
						chimpAction.comp.includeInLayout = false;
					}
				} else if (stringAction == ChimpConstants.ACTION_INVISABLE) {
					if(invert)
						chimpAction.comp.visible = true;
					else
						chimpAction.comp.visible = false;				
				} else if (stringAction == ChimpConstants.ACTION_DISABLE) {
					if(invert)
						chimpAction.comp.enabled = true;
					else
						chimpAction.comp.enabled = false;	
				} else if (stringAction == ChimpConstants.ACTION_VISABLE) {
					if(invert)
						chimpAction.comp.visible = false;
					else
						chimpAction.comp.visible = true;				
				} else if (stringAction == ChimpConstants.ACTION_ENABLE) {
					if(invert)
						chimpAction.comp.enabled = false;
					else
						chimpAction.comp.enabled = true;	
				}	
			}		
			
		}

		//check for permissions
		private static function isPermPresent(allowedPerms:String):Boolean {
			if(allowedPerms != null) {
				for each(var perm:String in _permissions) {
					if(perm != null && perm.length > 0 && allowedPerms.indexOf(perm) >= 0)
						return true;
				}
			}
			return false;
		}
	}
}
