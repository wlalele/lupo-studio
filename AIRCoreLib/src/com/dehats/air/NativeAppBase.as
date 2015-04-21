package com.dehats.air
{
	import air.update.ApplicationUpdaterUI;
	import air.update.events.StatusUpdateEvent;
	import air.update.events.UpdateEvent;
	
	import flash.data.EncryptedLocalStore;
	import flash.desktop.NativeApplication;
	import flash.display.NativeMenu;
	import flash.display.NativeWindow;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.InvokeEvent;
	import flash.filesystem.File;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;

	public class NativeAppBase extends EventDispatcher
	{

		public static const EVENT_LAUNCH:String="launch";
		public static const EVENT_SUBS_INVOKE:String="subsequentInvoke";
		public static const EVENT_CLOSING:String="closing";
		
		private static const ELSITEM_LAST_X:String="lastX";
		private static const ELSITEM_LAST_Y:String="lastY";
		private static const ELSITEM_LAST_WIDTH:String="lastWidth";
		private static const ELSITEM_LAST_HEIGHT:String="lastHeight";

		public var nativeApp:NativeApplication;
		public var parameters:Array;
		public var appName:String;
		public var appVersion:String;
		
		private var updaterConfigLocation:String;		
		private var nativeWin:NativeWindow;
		private var nativeMenu:NativeMenu;
		private var firstInvocation:Boolean=true;
		private var updater:ApplicationUpdaterUI = new ApplicationUpdaterUI();
		private var forceUpdates:Boolean;
		private var keepSizeAndPos:Boolean;
		private var lastX:int;
		private var lastY:int;
		private var lastWidth:int;
		private var lastHeight:int;

		
		public function NativeAppBase(pNativeApp:NativeApplication, pNativeMenu:NativeMenu=null, pForceUpdate:Boolean=false, pKeepSizeAndPos:Boolean=true,  pUpdaterFileLoc:String="app:/updaterConfig.xml")
		{
			nativeApp =pNativeApp;
			nativeApp.addEventListener(InvokeEvent.INVOKE, onInvoke);
			nativeApp.addEventListener(Event.EXITING, onExiting);
			
			nativeMenu =  pNativeMenu;

			var ns:Namespace = new Namespace(nativeApp.applicationDescriptor.namespaceDeclarations()[0]);
			appName = nativeApp.applicationDescriptor.ns::name;
			appVersion = nativeApp.applicationDescriptor.ns::version;
			
			updaterConfigLocation = pUpdaterFileLoc;
						
			forceUpdates = pForceUpdate;
			keepSizeAndPos = pKeepSizeAndPos;
		}
		
		public function init():void
		{
						
			nativeWin = (nativeApp.openedWindows[0] as NativeWindow);
			
			nativeWin.addEventListener(Event.CLOSING, onClosing);			
			
			activateMenu();
			
			if(keepSizeAndPos) readPosAndSize();
			else centerWindow();
		
			initializeUpdater();			
			
			//nativeWin.title += nativeWin.x +", "+nativeWin.y+" "+nativeWin.width+"*"+nativeWin.height;
		}

		// updater
		
		private function initializeUpdater():void
		{
			updater.configurationFile = new File (updaterConfigLocation);
			updater.addEventListener(UpdateEvent.INITIALIZED, updaterInitialized);
			updater.addEventListener(StatusUpdateEvent.UPDATE_STATUS, onUpdaterStatus);
			
			updater.initialize();				
		}
		
		private function updaterInitialized(event:UpdateEvent):void
		{
			checkForUpdates();
		}
		
		private function onUpdaterStatus(pEvt:StatusUpdateEvent):void
		{
			
			if( pEvt.available)
			{
				// Forces updates by hiding the main window if an update is available
				if(forceUpdates && nativeApp.activeWindow!=null) nativeApp.activeWindow.visible = false;
			}
		}

		public function checkForUpdates():void
		{
			updater.checkNow();
		}		

		// Invokation Mgmt
		
		private function onInvoke(pEvt:InvokeEvent):void
		{
			// Check if the invocation corresponds to the app launch 
			if(firstInvocation )
			{
				parameters = pEvt.arguments;
				dispatchEvent( new Event(EVENT_LAUNCH));				
				firstInvocation=false;								
			}
			else
			{
				dispatchEvent( new Event(EVENT_SUBS_INVOKE));				
			}
			
		}	
		
		private function activateMenu():void
		{
			// warning : this sets the window to visible=true
			if(nativeMenu)
			{
				if(NativeWindow.supportsMenu) nativeWin.menu= nativeMenu;
				if(NativeApplication.supportsMenu)  nativeApp.menu = nativeMenu;
			}	
		}			


		// Closing
		
		private function onClosing(pEvt:Event):void
		{
			pEvt.preventDefault();	
			dispatchEvent( new Event(EVENT_CLOSING));			
		}
		
		public function closeApp():void
		{	
			if(keepSizeAndPos) savePosAndSize(nativeWin.x, nativeWin.y, nativeWin.width, nativeWin.height);
			
			// Only to test first install !!
			//EncryptedLocalStore.reset();
			
			nativeApp.exit();
		}
		

		// workaround to fix the quit bug on OSX with the update framework			
		private function onExiting(pEvt:Event):void
		{
			var opened:Array = nativeApp.openedWindows;
			for (var i:int = 0; i < opened.length; i ++) {
				opened[i].close();
			}

		}
					
		// Size and pos
		
		public function centerWindow():void
		{
			nativeWin.width = nativeWin.minSize.x;
			nativeWin.height = nativeWin.minSize.y;
			
			setWindow((Capabilities.screenResolutionX - nativeWin.width) / 2, (Capabilities.screenResolutionY - nativeWin.height) / 2);
		}

		private function readPosAndSize():void
		{
			var xPosBytes:ByteArray = EncryptedLocalStore.getItem(ELSITEM_LAST_X);
			var yPosBytes:ByteArray = EncryptedLocalStore.getItem(ELSITEM_LAST_Y);
			var widthBytes:ByteArray = EncryptedLocalStore.getItem(ELSITEM_LAST_WIDTH);
			var heightBytes:ByteArray =  EncryptedLocalStore.getItem(ELSITEM_LAST_HEIGHT);
			
			if(xPosBytes==null || yPosBytes==null || widthBytes==null || heightBytes==null)
			{
				centerWindow();
				return;
			} 
			
			setWindow(xPosBytes.readInt(), yPosBytes.readInt(), widthBytes.readInt(), heightBytes.readInt());
			
		
		}
		
		private function setWindow(pX:int, pY:int, pWidth:int=0, pHeight:int=0):void
		{
			nativeWin.x = pX;
			nativeWin.y = pY;
			
			if(pWidth) nativeWin.width = pWidth;
			if(pHeight) nativeWin.height = pHeight;

			if(nativeWin.width < nativeWin.minSize.x) nativeWin.width = nativeWin.minSize.x;
			if(nativeWin.height < nativeWin.minSize.y) nativeWin.height = nativeWin.minSize.y;
			
		}
		
		
		private function savePosAndSize(pX:int, pY:int, pWidth:int, pHeight:int):void
		{
			
			var xPosBytes:ByteArray = new ByteArray();
			xPosBytes.writeInt(pX);

			var yPosBytes:ByteArray = new ByteArray();
			yPosBytes.writeInt(pY);

			var widthBytes:ByteArray = new ByteArray();
			widthBytes.writeInt(pWidth);

			var heightBytes:ByteArray = new ByteArray();
			heightBytes.writeInt(pHeight);
			
			EncryptedLocalStore.setItem( ELSITEM_LAST_X, xPosBytes  );		
			EncryptedLocalStore.setItem( ELSITEM_LAST_Y,  yPosBytes );		
			EncryptedLocalStore.setItem( ELSITEM_LAST_WIDTH, widthBytes);		
			EncryptedLocalStore.setItem( ELSITEM_LAST_HEIGHT, heightBytes );	
		}
		
		
	}
}