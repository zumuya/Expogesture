/*
	Copyright (C) 2003-2006 NAKAHASHI Ichiro

	This program is distributed under the GNU Public License.
	This program comes with NO WARRANTY.
*/

#import <Carbon/Carbon.h>

#import <limits.h>
#import <math.h>
#import <sys/time.h>

#import "EGCommon.h"
#import "EGController.h"
#import "EGPreference.h"
#import "HotkeyEvent.h"
#import "EGNotificationView.h"
#import "FloatingWindow.h"
#import "NSScreen-EGExt.h"

// Note: The order of EGMoveDirection constants are important;
// see method _mouseHasMovedBy:
typedef enum {
	EGMDNil,
	EGMDStraightNW,
	EGMDStraightW,
	EGMDStraightSW,
	EGMDStraightS,
	EGMDStraightSE,
	EGMDStraightE,
	EGMDStraightNE,
	EGMDStraightN,
	EGMDRotateRight,
	EGMDRotateLeft,
} EGMoveDirection;

static const EGMoveDirection EGGTRotateRight[] =
	{EGMDRotateRight, EGMDNil};
static const EGMoveDirection EGGTRotateLeft[] =
	{EGMDRotateLeft, EGMDNil};
static const EGMoveDirection EGGTHorizontal[] =
	{EGMDStraightE, EGMDStraightW, EGMDStraightE, EGMDStraightW,
		EGMDNil};
static const EGMoveDirection EGGTVertical[] =
	{EGMDStraightN, EGMDStraightS, EGMDStraightN, EGMDStraightS,
		EGMDNil};
static const EGMoveDirection EGGTZPath[] =
	{EGMDStraightE, EGMDStraightSW, EGMDStraightE, EGMDStraightNW,
		EGMDNil};
static const EGMoveDirection EGGTNPath[] =
	{EGMDStraightN, EGMDStraightSE, EGMDStraightN, EGMDStraightSW,
		EGMDNil};
static const EGMoveDirection *GestureTemplates[] = {
	EGGTRotateRight,
	EGGTRotateLeft,
	EGGTHorizontal,
	EGGTVertical,
	EGGTZPath,
	EGGTNPath,
};
static const int GestureTemplateCount
		= sizeof(GestureTemplates) / sizeof(EGMoveDirection *);

@implementation EGController

- (void) _resetGestureProgresses
{
	int idx;
	for (idx = 0; idx < GestureTemplateCount; idx++)
		gestureProgresses[idx] = 0;
}

- (void)_showNotifWindowWithText:(NSString *)text
{
	// Notification window should not averlap mouse pointer...
	static NSPoint notifWindowPosList[] = {
	{0.5,  0.5 },   // center
	{0.25, 0.75},   // upper-right
	{0.75, 0.75},   // upper-left
	{0.25, 0.25},   // lower-right
	{0.75, 0.25},   // lower-left
	};
	
	NSRect screenRect = [[NSScreen screenUnderMouse] frame];
	NSRect viewFrame;
	NSSize textSize, windowSize;;

	[notifView setText:text];
	
	viewFrame = [notifView frame];
	textSize = [[notifView attributedStringValue] size];
	windowSize.width = textSize.width + viewFrame.size.height * 2.0;
	windowSize.height = viewFrame.size.height;
	if (windowSize.width > screenRect.size.width / 2.2) {
		windowSize.width = screenRect.size.width / 2.2;
	}
	[notifWindow setContentSize:windowSize];
	
	NSUserDefaults *udef = [NSUserDefaults standardUserDefaults];
	int posIdx = [udef integerForKey:@"NotifWindowPosition"];
	NSPoint wp = notifWindowPosList[posIdx];
	wp.x = wp.x * screenRect.size.width + screenRect.origin.x;
	wp.y = wp.y * screenRect.size.height + screenRect.origin.y;
	[notifWindow setFrameCenteredAt:wp];
	
	[notifWindow orderFrontRegardless];

	[notifWindowTimer invalidate];	// reset timer if already shown
	notifWindowTimer =
			[NSTimer scheduledTimerWithTimeInterval: 0.4f
						target: self
						selector: @selector(_dismissNotifWindow:)
						userInfo: nil
						repeats: NO];
}

-(void)sendKeyEventWithKeyCode: (CGKeyCode)keyCode flags: (CGEventFlags)flags isDown: (BOOL)isDown
{
	CGEventRef event = CGEventCreateKeyboardEvent(nil, keyCode, isDown);
	if (flags) {
		CGEventSetFlags(event, flags);
	}
	CGEventPost(kCGSessionEventTap, event);
	CFRelease(event);
}

- _generateKeyEvent:(HotkeyEvent *)hotkeyEvent
{
	[self _showNotifWindowWithText:[hotkeyEvent localizedDescription]];

	CGEventFlags flags = 0;
	if (hotkeyEvent.ctrl) flags |= kCGEventFlagMaskControl;
	if (hotkeyEvent.alt) flags |= kCGEventFlagMaskAlternate;
	if (hotkeyEvent.cmd) flags |= kCGEventFlagMaskCommand;
	if (hotkeyEvent.shift) flags |= kCGEventFlagMaskShift;

	[self sendKeyEventWithKeyCode: hotkeyEvent.keyCode flags: flags isDown: true];
	[self sendKeyEventWithKeyCode: hotkeyEvent.keyCode flags: flags isDown: false];
	
	return self;
}


AXUIElementRef _menuItemForTitle(AXUIElementRef menuBarRef, NSString *targetTitle)
{
	AXError err;
	
	
	CFTypeRef menuItemArray_cf = NULL;
	// Obtain List of Child Items
	err = AXUIElementCopyAttributeValue(menuBarRef, kAXChildrenAttribute, &menuItemArray_cf);
	if (err != kAXErrorSuccess) return nil;		// Leaf node, no children.
	
	NSArray *menuItemArray = (__bridge_transfer id)menuItemArray_cf;
	int menuCount = [menuItemArray count];
	
	AXUIElementRef menuItem;
	id menuTitle;
	int i;
	
	for (i = 0; i < menuCount; i++) {
		
		menuItem = (__bridge AXUIElementRef)[menuItemArray objectAtIndex:i];
		
		// Check for Titles
		CFTypeRef menuTitle_cf = NULL;
		err = AXUIElementCopyAttributeValue(menuItem, kAXTitleAttribute, &menuTitle_cf);
		if (err == kAXErrorSuccess) {
			menuTitle = (__bridge_transfer id)menuTitle_cf;
			if ([menuTitle isEqualTo:targetTitle]) return menuItem;
		}

		// Dig Into Child Nodes
		menuItem = (__bridge AXUIElementRef)[menuItemArray objectAtIndex:i];
		menuItem = _menuItemForTitle(menuItem, targetTitle);
		if (menuItem) {
			return menuItem;
		}
	}
	
	return nil;
}

- (NSRunningApplication*)activeApplication
{
	for (NSRunningApplication* app in NSWorkspace.sharedWorkspace.runningApplications) {
		if ([app isActive]) {
			return app;
		}
	}
	return nil;
}

- (void)_pickMenuItemForPseudoEvent:(HotkeyEvent *)thisEvent
{
	AXError err;
	AXUIElementRef targetMenuItem;
	id targetMenuTitle;
	
	NSString *menuLabel = [thisEvent menuLabel];
	[self _showNotifWindowWithText:menuLabel];
	
	pid_t activeAppPid = [self activeApplication].processIdentifier;
	
	// Check if target menu item is cached
	if ([thisEvent pidCache] == activeAppPid) {
		targetMenuItem = [thisEvent menuItemRefCache];
		CFTypeRef value = NULL;
		err = AXUIElementCopyAttributeValue(targetMenuItem, kAXTitleAttribute, &value);
		targetMenuTitle = (__bridge_transfer id)value;
		if (err == kAXErrorSuccess) {
			if  ([targetMenuTitle isEqualToString:[thisEvent menuLabel]])
				goto pickMenu;  // Found; do it immediately
		}
	}
	
	// Item is not cached. Get Top-level UIElement for Frontmost Application
	AXUIElementRef appRef = AXUIElementCreateApplication(activeAppPid);
	
	// Get Menu Bar UIElement
	AXUIElementRef menuBarRef;
	err = AXUIElementCopyAttributeValue(appRef, kAXMenuBarAttribute, (CFTypeRef *)&menuBarRef);
	if (err != kAXErrorSuccess) {
		if (err == kAXErrorAPIDisabled) {
			NSLog(@"Accessibility API is disabled. Please turn it on at System Preferences.");
		} else {
			NSLog(@"Could not obtain AXUIElement for application menu bar. err=%d", err);
		}
		return;
	}
	if (appRef) CFRelease(appRef);
	
	// Find Menu Item Labeled 'menuLabel'
	targetMenuItem = _menuItemForTitle(menuBarRef, menuLabel);
	if (menuBarRef) CFRelease(menuBarRef);
	
	// Cache it for later re-use
	[thisEvent setPidCache:activeAppPid];
	[thisEvent setMenuItemRefCache:targetMenuItem];
	
pickMenu:
	// Actually pick it (or "execute" it)
	if (targetMenuItem) {
		err = AXUIElementPerformAction(targetMenuItem, kAXPickAction);
	} else {
		NSBeep();
		NSLog(@"Menu “%@” not found.", menuLabel);
	}
}


- (BOOL)_isModifiersPressed
{
	BOOL flag = NO;
	KeyMap km;
	long k;
	enum {
		km1ShiftMask = 0x1,
		km1AltMask = 0x4,
		km1CtrlMask = 0x8,
		km1SpaceMask = 0x200,
		km1CmdMask = 0x8000,
	};
	
	GetKeys(km);
	//NSLog(@"%X %X %X %X", km[0], km[1], km[2], km[3]);
	#if TARGET_RT_LITTLE_ENDIAN
	k = CFSwapInt32BigToHost(km[1].bigEndianValue);
	#else
	k = km[1];
	#endif
	if (k & (km1ShiftMask | km1AltMask | km1CtrlMask |
			km1SpaceMask | km1CmdMask)) flag |= YES;
	if (NSEvent.pressedMouseButtons != 0) flag |= YES;
	return flag;
}

- _generatePseudoEvent:(int)eventId
{
	NSArray *appHotkeyDefs;
	HotkeyEvent *thisKey;

	if ([self _isModifiersPressed]) {
		NSLog(@"A gesture has been blocked "
				@"because some modifiers are pressed.");
		return self;
	}
	
	appHotkeyDefs = [eventKeyDefs objectForKey:
			self.activeApplication.bundleURL.path];
	if (appHotkeyDefs) {
		thisKey = [appHotkeyDefs objectAtIndex:eventId];
		if ([thisKey pseudoEventType] == HotkeyInherit) {
			thisKey = [keyDefsGlobal objectAtIndex:eventId];
		}
	} else {
		thisKey = [keyDefsGlobal objectAtIndex:eventId];
	}

	switch ([thisKey pseudoEventType]) {
	case HotkeyDisabled:
		NSLog(@"This event is disabled.");
		break;
	case HotkeyNormalEvent:
		[self _generateKeyEvent:thisKey];
		break;
	case HotkeyMenuItem:
		[self _pickMenuItemForPseudoEvent:thisKey];
		break;
	default:
		NSLog(@"Unknown pseudo event type %d", [thisKey pseudoEventType]);
	}
	return self;
}

- _composeGesture:(EGMoveDirection)thisMove;
{
	int eventId = -1, idx;
	struct timeval tv;
	unsigned long thisTimestamp;
	
	gettimeofday(&tv, NULL);
	thisTimestamp = tv.tv_sec * 1000 + (tv.tv_usec / 1000);
	
	// Block gestures if input comes too frequent.
	if (thisTimestamp - lastIssuedTimestamp < 800)
		return self;

	// Reset all gesture recognitions if input comes too slow.
	if (thisTimestamp - lastMoveTimestamp > 300) {
		[self _resetGestureProgresses];
	}
	
	for (idx = 0; idx < GestureTemplateCount; idx++) {
		int *gp = &gestureProgresses[idx];
		if (GestureTemplates[idx][*gp] == thisMove) {
			(*gp)++;
			if (GestureTemplates[idx][*gp] == EGMDNil) {
				eventId = idx;
				break;
			}
		}
	}
	if (eventId >= 0) {
		[self _generatePseudoEvent:eventId];
		[self _resetGestureProgresses];
		lastIssuedTimestamp = thisTimestamp;
	}

	lastMoveTimestamp = thisTimestamp;
	return self;
}

-(void)_dismissNotifWindow:userInfo
{
	[notifWindow orderOutWithFade:self];
	notifWindowTimer = nil;
}

//#define DEBUGME
- (void)_mouseHasMovedBy:(NSSize)move
{
#ifdef DEBUGME
	static int debugCount = 0;
#endif
	int nowDirection;
	int nowRotation;
	float nowSpeed, nowDPhi;
	float meanSpeed;
	float meanDPhi;
	struct timeval tv;
	unsigned long thisTimestamp;

	if (sessionIsHidden) return;
	
	gettimeofday(&tv, NULL);
	thisTimestamp = tv.tv_sec * 1000 + (tv.tv_usec / 1000);
	if (thisTimestamp - lastMouseMoveTimestamp > mouseMoveTimeout) {
		currentDirection = 0;
		currentRotation = 0;
		//NSLog(@"mouseHasMovedBy: - timeout (%ld)", thisTimestamp - lastMouseMoveTimestamp);
	}
	
	nowPhi = atan2(move.width, move.height);
	nowSpeed = sqrt(move.width*move.width + move.height*move.height);
	nowDPhi = lastPhi - nowPhi;
	if (nowDPhi > M_PI) nowDPhi -= 2*M_PI;
	else if (nowDPhi < -M_PI) nowDPhi += 2*M_PI;
	
	meanSpeed = (lastSpeed + nowSpeed) / 2;
	meanDPhi = (lastDPhi + nowDPhi) / 2;
	
	// Check whether pointer is moving straight-forward
	nowDirection = (int)floorf(nowPhi/M_PI_4 + 4.5);
	if (nowDirection == 0) nowDirection = 8;
	if (currentDirection == nowDirection) {
		motionAmount += nowSpeed;
		//NSLog(@"ma=%d (min=%d)", motionAmount, gestureSizeMin);
		if (motionAmount >= gestureSizeMin) {
			//NSLog(@"nowDirection=%d", nowDirection);
			[self _composeGesture:nowDirection];
			motionAmount = INT_MIN;
		}
	} else {
		currentDirection = nowDirection;
		motionAmount = 0;
	}

	// Check if pointer is making a part of arc
	float absDPhi = fabs(meanDPhi);
	if (M_PI/5.0 > absDPhi && absDPhi > 0.08) {
		float radius = meanSpeed / sin(absDPhi);
		//NSLog(@"r=%.1f", radius);
		if (radius * 2 >= gestureSizeMin) {
			nowRotation = meanDPhi > 0 ? EGMDRotateRight : EGMDRotateLeft;
			if (currentRotation != nowRotation) {
				currentRotation = nowRotation;
				rotateAmount = 0.0;
			}
			rotateAmount += absDPhi;
			if (rotateAmount > M_PI*2) {
				[self _composeGesture:nowRotation];
				rotateAmount = 0.0;
			}
		}
	}

	// Note that detection processes of lines and circles are
	// non-exclusive.
	
#ifdef DEBUGME
	//printf("(%.2f) ", nowSpeed);
	printf("(%d, %.2f) ", nowDirection, nowPhi);
	if (debugCount ++ > 5) {
		debugCount = 0;
		printf("¥n");
	}
#endif
	lastPhi = nowPhi;
	lastDPhi = nowDPhi;
	lastSpeed = nowSpeed;
	lastMouseMoveTimestamp = thisTimestamp;
}

- (void)_timerEvent:userInfo
{
	NSPoint currentPoint = [NSEvent mouseLocation];
	NSSize mouseMove = NSMakeSize(
			currentPoint.x - lastMousePoint.x,
			- (currentPoint.y - lastMousePoint.y));	// flip Y coord.
	if (mouseMove.width || mouseMove.height)
		[self _mouseHasMovedBy:mouseMove];
	lastMousePoint = currentPoint;
}

- (void)_userSwitchHandler:(NSNotification *)notif
{
	sessionIsHidden = [[notif name] isEqualToString:NSWorkspaceSessionDidResignActiveNotification];
	NSLog(@"Sesssion becomes %@", sessionIsHidden ? @"Hidden" : @"Visible");
}

void _reopenApplication(ProcessSerialNumber psn)
{
	OSStatus err;
	AEAddressDesc targetDesc;
	AppleEvent ev;
	
	err = AECreateDesc(typeProcessSerialNumber, &psn, sizeof(psn), &targetDesc);
	err = AECreateAppleEvent(kCoreEventClass, kAEReopenApplication, &targetDesc, kAutoGenerateReturnID, kAnyTransactionID, &ev);
	err = AESendMessage(&ev, NULL, kAENoReply, kAEDefaultTimeout);
}

- init
{
	self = [super init];

	// Check if Expogesture is already running
	NSMutableArray<NSRunningApplication*>* otherInstances = [NSRunningApplication runningApplicationsWithBundleIdentifier: NSBundle.mainBundle.bundleIdentifier].mutableCopy;
	[otherInstances removeObject: NSRunningApplication.currentApplication];
	if (otherInstances.count > 0) {
		[otherInstances.firstObject activateWithOptions: NSApplicationActivateAllWindows];
		[NSApp terminate:self];
	}

	// Install Fast User Switch Handler
	NSNotificationCenter *sharedCenter =
			[[NSWorkspace sharedWorkspace] notificationCenter];
	[sharedCenter
			addObserver:self
			selector:@selector(_userSwitchHandler:)
			name:NSWorkspaceSessionDidBecomeActiveNotification 
			object:nil];
	[sharedCenter
			addObserver:self 
			selector:@selector(_userSwitchHandler:)
			name:NSWorkspaceSessionDidResignActiveNotification 
			object:nil];

	gestureProgresses = malloc(sizeof(int) * GestureTemplateCount);
	[self _resetGestureProgresses];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *keyDefsDict;
	
	mouseMoveTimeout = 100;		// in msec
	pointerPollingInterval = 0.02;	// in sec

	// Load default user defaults
	NSDictionary *defaultDefaults =
			[NSDictionary dictionaryWithContentsOfFile:
				[[NSBundle mainBundle]
					pathForResource:@"DefaultDefaults"
					ofType:@"plist"]];
	[defaults registerDefaults:defaultDefaults];

	gestureSizeMin = [defaults integerForKey:@"GestureSizeMin"];

	// Construct pseudo key-event definitions from user defaults, or create
	// new one on failure.
	eventKeyDefs = [[NSMutableDictionary alloc] init];
	keyDefsDict = [defaults objectForKey:@"EventKeyDefs"];
	for (NSString* appName in keyDefsDict.allKeys) {
		NSArray* appArray = [keyDefsDict objectForKey: appName];
		NSArray* hotkeys = [HotkeyEvent hotkeyArrayWithArray: appArray
				count: GestureTemplateCount
				global: [appName isEqualToString: EGGlobalAppName]];
		[eventKeyDefs setObject: hotkeys forKey: appName];
		if ([appName isEqualToString: EGGlobalAppName]) {
			keyDefsGlobal = hotkeys;
		}
	}
	
	return self;
}

- (void)dealloc
{
	free(gestureProgresses);
}

- (void)awakeFromNib
{
	// Setup a notification window, which is shown when pseudo key-event
	// is generated.
	[notifWindow setIgnoresMouseEvents:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	if ([defaults boolForKey:@"ShowStatusBarMenu"]) {
		[self showStatusBarMenu];
	}
	
	mousePollTimer =
		[NSTimer scheduledTimerWithTimeInterval: pointerPollingInterval
						target: self
						selector: @selector(_timerEvent:)
						userInfo: nil
						repeats: YES];
	[mousePollTimer setTolerance: (pointerPollingInterval * 0.25)];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	[notifWindowTimer invalidate];

	[mousePollTimer invalidate];
}


- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag
{
	[prefController openPreferenceWindow:self];
	return NO;
}


- (void)showStatusBarMenu
{
	if (statusItem) return;
	
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	statusItem = [bar statusItemWithLength:NSVariableStatusItemLength];
	[statusItem.button setImage:[NSImage imageNamed:@"StatusBarIcon"]];
	[statusItem setMenu:statusMenu];
}


- (void)hideStatusBarMenu
{
	if (!statusItem) return;
	
	NSStatusBar *bar = [NSStatusBar systemStatusBar];
	[bar removeStatusItem:statusItem];
	statusItem = nil;
}


- (IBAction)showAboutPanel:sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:self];
}


- (NSMutableDictionary *)eventKeyDefs
{
	return eventKeyDefs;
}

- (int)gestureSizeMin
{
	return gestureSizeMin;
}

- setGestureSizeMin:(int)min
{
	gestureSizeMin = min;
	return self;
}

@end
