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
#import "HIDManager.h"
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
            [NSTimer scheduledTimerWithTimeInterval: 1.0
                        target: self
                        selector: @selector(_dismissNotifWindow:)
                        userInfo: nil
                        repeats: NO];
}


- _generateKeyEvent:(HotkeyEvent *)thisKey
{
    [self _showNotifWindowWithText:[thisKey localizedDescription]];

    if ([thisKey ctrl])  CGPostKeyboardEvent(0, 59, true);
    if ([thisKey alt])   CGPostKeyboardEvent(0, 58, true);
    if ([thisKey cmd])   CGPostKeyboardEvent(0, 55, true);
    if ([thisKey shift]) CGPostKeyboardEvent(0, 56, true);
    
    CGPostKeyboardEvent(0, [thisKey keyCode], true);
    CGPostKeyboardEvent(0, [thisKey keyCode], false);

    if ([thisKey shift]) CGPostKeyboardEvent(0, 56, false);
    if ([thisKey cmd])   CGPostKeyboardEvent(0, 55, false);
    if ([thisKey alt])   CGPostKeyboardEvent(0, 58, false);
    if ([thisKey ctrl])  CGPostKeyboardEvent(0, 59, false);
    
    return self;
}


AXUIElementRef _menuItemForTitle(AXUIElementRef menuBarRef, NSString *targetTitle)
{
	AXError err;
	NSArray *menuItemArray;
	
	// Obtain List of Child Items
	err = AXUIElementCopyAttributeValue(menuBarRef, kAXChildrenAttribute, (CFTypeRef *)&menuItemArray);
	if (err != kAXErrorSuccess) return nil;		// Leaf node, no children.
	[menuItemArray autorelease];
	int menuCount = [menuItemArray count];
	
	AXUIElementRef menuItem;
	id menuTitle;
	int i;
	
	for (i = 0; i < menuCount; i++) {
	
		// Check for Titles
		menuItem = (AXUIElementRef)[menuItemArray objectAtIndex:i];
		err = AXUIElementCopyAttributeValue(menuItem, kAXTitleAttribute, (CFTypeRef *)&menuTitle);
		if (err == kAXErrorSuccess) {
			[menuTitle autorelease];
			if ([menuTitle isEqualTo:targetTitle]) return menuItem;
		}

		// Dig Into Child Nodes
		menuItem = (AXUIElementRef)[menuItemArray objectAtIndex:i];
		menuItem = _menuItemForTitle(menuItem, targetTitle);
		if (menuItem) {
			return menuItem;
		}
	}
	
	return nil;
}


- (void)_pickMenuItemForPseudoEvent:(HotkeyEvent *)thisEvent
{
	AXError err;
	AXUIElementRef menuBarRef;
	AXUIElementRef targetMenuItem;
	id targetMenuTitle;
	
	NSString *menuLabel = [thisEvent menuLabel];
	[self _showNotifWindowWithText:menuLabel];
	
	NSDictionary *activeAppDict = [[NSWorkspace sharedWorkspace] activeApplication];
	pid_t activeAppPid = [[activeAppDict objectForKey:@"NSApplicationProcessIdentifier"] intValue];
	
	// Check if target menu item is cached
	if ([thisEvent pidCache] == activeAppPid) {
		targetMenuItem = [thisEvent menuItemRefCache];
		err = AXUIElementCopyAttributeValue(targetMenuItem, kAXTitleAttribute, (CFTypeRef *)&targetMenuTitle);
		if (err == kAXErrorSuccess) {
			[targetMenuTitle autorelease];
			if  ([targetMenuTitle isEqualToString:[thisEvent menuLabel]])
				goto pickMenu;  // Found; do it immediately
		}
	}
	
	// Item is not cached. Get Top-level UIElement for Frontmost Application
	AXUIElementRef appRef = AXUIElementCreateApplication(activeAppPid);
	[(id)appRef autorelease];
	
	// Get Menu Bar UIElement
	err = AXUIElementCopyAttributeValue(appRef, kAXMenuBarAttribute, (CFTypeRef *)&menuBarRef);
	if (err != kAXErrorSuccess) {
		if (err == kAXErrorAPIDisabled) {
			NSLog(@"Accessibility API is disabled. Please turn it on at System Preferences.");
		} else {
			NSLog(@"Could not obtain AXUIElement for application menu bar. err=%d", err);
		}
		return;
	}
	[(id)menuBarRef autorelease];
	
	// Find Menu Item Labeled 'menuLabel'
	targetMenuItem = _menuItemForTitle(menuBarRef, menuLabel);
	
	// Cache it for later re-use
	[thisEvent setPidCache:activeAppPid];
	[thisEvent setMenuItemRefCache:targetMenuItem];
	
pickMenu:
	// Actually pick it (or "execute" it)
	if (targetMenuItem) {
		err = AXUIElementPerformAction(targetMenuItem, kAXPickAction);
	} else {
		NSBeep();
		NSLog(@"Menu \"%@\" not found.", menuLabel);
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
    if (Button()) flag |= YES;
    return flag;
}

- _generatePseudoEvent:(int)eventId
{
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSArray *appHotkeyDefs;
    HotkeyEvent *thisKey;

    if ([self _isModifiersPressed]) {
        NSLog(@"A gesture has been blocked "
                @"because some modifiers are pressed.");
        return self;
    }
    
    appHotkeyDefs = [eventKeyDefs objectForKey:
            [[workspace activeApplication] 
                objectForKey:@"NSApplicationPath"]];
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
        printf("\n");
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

- (void)_hidEventCallback:sender
{
    HRESULT hwRet;
    IOHIDEventStruct event;
    NSSize move = NSZeroSize;
    NSEnumerator *anEnum;
    HIDElement *elem;
    
    while ((hwRet = [sender nextEvent:&event]) == kIOReturnSuccess) {
    
        anEnum = [mouseMoveXElements objectEnumerator];
        while (elem = [anEnum nextObject]) {
            if (sender == elem->hidDevice &&
                    event.elementCookie == elem->cookie) {
                move.width += event.value;
                goto nextEvent;
            }
        }

        anEnum = [mouseMoveYElements objectEnumerator];
        while (elem = [anEnum nextObject]) {
            if (sender == elem->hidDevice &&
                    event.elementCookie == elem->cookie) {
                move.height += event.value;
                goto nextEvent;
            }
        }

    nextEvent:
        continue;
    }
    
    if (move.width || move.height) {
        [self _mouseHasMovedBy:move];
        //NSLog(@"mouseEventCallback: - %@", NSStringFromSize(move));
    }
}

- (IOHIDElementCookie)_registerCookieForDevice:(HIDDevice *)dev
        page:(UInt32)page usage:(UInt32)usage
        elementsArray:(NSMutableArray *)elemArray
{
    IOHIDElementCookie cookie;

    cookie = [dev elementCookieForUsagePage:page usage:usage];
    [dev queueAddElement:cookie];
    NSLog(@"Cookie has succesfully registered to the queue for dev=%@ page=%d usage=%d",
                    [dev className], page, usage);
                    
    [elemArray addObject:[HIDElement elementWithDevice:dev cookie:cookie]];
    return cookie;
}

- (void)_deviceRemovedCallback:(HIDDevice *)device
{
    NSMutableArray *ea;
    NSEnumerator *eaEnum =
            [[NSArray arrayWithObjects:
                mouseMoveXElements, mouseMoveYElements, nil] objectEnumerator];

    while (ea = [eaEnum nextObject]) {
        int idx;
        HIDElement *e;
        for (idx = 0; idx < [ea count]; idx++) {
            e = [ea objectAtIndex:idx];
            if (e->hidDevice == device) [ea removeObjectAtIndex:idx];
        }
    }
    
    [hidDevices removeObject:device];
}

- (void)_miceAddedCallback:(NSArray *)devArray
{
    HIDDevice *dev;
    int idx;
    
    NSLog(@"%d mice found.", [devArray count]);
    for (idx = 0; idx < [devArray count]; idx++)  {
        dev = [devArray objectAtIndex:idx];
        [hidDevices addObject:dev];

        if (!usePollingToTrackPointer) {
            [self _registerCookieForDevice:dev
                    page:kHIDPage_GenericDesktop usage:kHIDUsage_GD_X
                    elementsArray:mouseMoveXElements];
    
            [self _registerCookieForDevice:dev
                    page:kHIDPage_GenericDesktop usage:kHIDUsage_GD_Y
                    elementsArray:mouseMoveYElements];
        }
        
        [dev setEventCallbackSelector:@selector(_hidEventCallback:) target:self];
        [dev setRemovedCallbackSelector:@selector(_deviceRemovedCallback:) target:self];
    }
}

- (void)_setupHIDQueues
{
    hidDevices = [[NSMutableArray alloc] init];
    mouseMoveXElements = [[NSMutableArray alloc] init];
    mouseMoveYElements = [[NSMutableArray alloc] init];

    [[HIDManager alloc]
            initWithDeviceAttachedCallbackSelector:@selector(_miceAddedCallback:)
            target:self
            forPrimaryUsagePage:kHIDPage_GenericDesktop
            usage:kHIDUsage_GD_Mouse];
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
    [super init];

    // Check if Expogesture is already running
    ProcessSerialNumber psn = {kNoProcess, kNoProcess}, myPsn;
    NSDictionary *pid;
    Boolean psnIsSame;
    GetCurrentProcess(&myPsn);
    while (GetNextProcess(&psn) != procNotFound) {
        pid = (NSDictionary *)ProcessInformationCopyDictionary(
                &psn, kProcessDictionaryIncludeAllInformationMask);
        SameProcess(&psn, &myPsn, &psnIsSame);
        if ([[pid objectForKey:@"CFBundleName"] isEqualToString:@"Expogesture"]
                && !psnIsSame)  {
            NSLog(@"Another copy is running.  Reopening it...");
            _reopenApplication(psn);
            [NSApp terminate:self];
        }
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
    
    // Setup from defaults
    usePollingToTrackPointer =
            [defaults boolForKey:@"UsePollingToTrackPointer"];
    NSLog(@"Polling timer is used to track pointer: %@", 
            StringFromBOOL(usePollingToTrackPointer));

    gestureSizeMin = [defaults integerForKey:@"GestureSizeMin"];

    // Construct pseudo key-event definitions from user defaults, or create
    // new one on failure.
    eventKeyDefs = [[NSMutableDictionary alloc] init];
    keyDefsDict = [defaults objectForKey:@"EventKeyDefs"];
    NSString *appName;
    NSEnumerator *anEnum = [[keyDefsDict allKeys] objectEnumerator];
    while (appName = [anEnum nextObject]) {
        NSArray *appArray = [keyDefsDict objectForKey:appName];
        NSArray *hotkeys = [HotkeyEvent hotkeyArrayWithArray:appArray
                count:GestureTemplateCount
                global:[appName isEqualToString:EGGlobalAppName]];
        [eventKeyDefs setObject:hotkeys forKey:appName];
        if ([appName isEqualToString:EGGlobalAppName])
            keyDefsGlobal = hotkeys;
    }
    
    return self;
}

- (void)dealloc
{
    [notifWindow release];
    [appSwitchWindow release];
    
    free(gestureProgresses);
	
	[super dealloc];
}

- (void)awakeFromNib
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Setup a notification window, which is shown when pseudo key-event
    // is generated.
    [notifWindow setIgnoresMouseEvents:YES];
    
    // Setup an AppSwitch window
    [appSwitchView setBringsAllWindowsToFront:
            [defaults boolForKey:@"BringsAllWindowsToFront"]];
    [appSwitchView setCreatesNewDocumentIfNone:
            [defaults boolForKey:@"CreatesNewDocumentIfNone"]];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if ([defaults boolForKey:@"ShowStatusBarMenu"]) {
        [self showStatusBarMenu];
    }
    
    // We no longer setup HID queue interface when polling option is set
	// to prevent crash on startup...
    if (usePollingToTrackPointer) {
        mousePollTimer =
            [NSTimer scheduledTimerWithTimeInterval: pointerPollingInterval
                            target: self
                            selector: @selector(_timerEvent:)
                            userInfo: nil
                            repeats: YES];
    } else {
		[self _setupHIDQueues];
	}	
}


- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    [notifWindowTimer invalidate];

    [mousePollTimer invalidate];
    [hidDevices release];
    [mouseMoveXElements release];
    [mouseMoveYElements release];
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
    [statusItem retain];
    [statusItem setImage:[NSImage imageNamed:@"StatusBarIcon"]];
    [statusItem setHighlightMode:YES];
    [statusItem setMenu:statusMenu];
}


- (void)hideStatusBarMenu
{
    if (!statusItem) return;
    
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    [bar removeStatusItem:statusItem];
    [statusItem release];
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
