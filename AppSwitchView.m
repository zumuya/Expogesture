/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Carbon/Carbon.h>
#import "AppSwitchView.h"

#define PSNEqual(psn1, psn2) \
        (psn1.lowLongOfPSN == psn2.lowLongOfPSN && \
        psn1.highLongOfPSN == psn2.highLongOfPSN)

@implementation AppSwitchView

- (NSMutableDictionary *)_selectedApp:(NSEvent *)event
{
    NSRect viewRect = [self bounds];
    NSPoint origin = NSMakePoint(viewRect.size.width  / 2,
                                 viewRect.size.height / 2);
    NSPoint mp = [self convertPoint:[event locationInWindow] fromView:nil];
    
    float dx = mp.x - origin.x;
    float dy = mp.y - origin.y;
    float r = sqrt(dx * dx + dy * dy);
    float p = atan2(dx, dy);
    
    if (r > AppSwitchMenuRadius + iconSize / 2
        || AppSwitchMenuRadius - iconSize / 2 > r)
        return nil;

    if (p < 0) p += M_PI * 2;
    int c = [runningApps count];
    int i = (int)(p * c / (M_PI * 2) + .5) % c;
    //NSLog(@"index = %d", i);
    return [runningApps objectAtIndex:i];
}


- (void)_launchedAppStatusChanged:notif
{
    NSDictionary *appDict;

    NSRect imageRect = [self bounds];
    NSPoint menuOrigin = NSMakePoint(
            imageRect.size.width  / 2,
            imageRect.size.height / 2);

    // Forget all
    [runningApps release];
    runningApps = nil;
    
    // Build new list of running applications
    NSWorkspace *ws = [NSWorkspace sharedWorkspace];
    NSArray *wsApps = [ws launchedApplications];
    runningApps = [[NSMutableArray alloc] init];
    int idx, appCount = [wsApps count];
    
    iconSize = 2 * M_PI * AppSwitchMenuRadius / appCount / M_SQRT2;
    if (iconSize > AppSwitchBaseIconSize)
        iconSize = AppSwitchBaseIconSize;

    for (idx = 0; idx < appCount; idx++) {
        NSMutableDictionary *mutableDict;
        NSImage *appIcon;

        appDict = [wsApps objectAtIndex:idx];
        mutableDict = [[appDict mutableCopy] autorelease];
        appIcon = [ws iconForFile:
                [appDict objectForKey:@"NSApplicationPath"]];
        [mutableDict setObject:appIcon forKey:@"AppIcon"];
        [mutableDict setObject:[NSNumber numberWithFloat:0.0]
                forKey:@"ZoomFactor"];

        float phy = 2 * M_PI * idx / appCount;
        NSPoint iconCenter = NSMakePoint(
                menuOrigin.x + sin(phy)*AppSwitchMenuRadius,
                menuOrigin.y + cos(phy)*AppSwitchMenuRadius);
        NSRect iconRect = NSMakeRect(
                iconCenter.x - iconSize/2,
                iconCenter.y - iconSize/2,
                iconSize, iconSize);
        [mutableDict setObject:[NSValue valueWithPoint:iconCenter]
                forKey:@"IconCenter"];
        [mutableDict setObject:[NSValue valueWithRect:iconRect]
                forKey:@"IconRect"];
        [runningApps addObject:mutableDict];
    }
    selectedAppDict = nil;
    [self setNeedsDisplay:YES];
}

- initWithFrame:(NSRect)frameRect
{
    [super initWithFrame:frameRect];
    
    NSMutableParagraphStyle *ps;
    ps = [[[NSParagraphStyle defaultParagraphStyle]
            mutableCopy] autorelease];
    [ps setAlignment:NSCenterTextAlignment];
    
    textAttr = [[NSMutableDictionary alloc] init];
    [textAttr setObject:ps
            forKey:NSParagraphStyleAttributeName];
    [textAttr
            setObject:[NSFont boldSystemFontOfSize:AppSwitchCaptionFontSize]
            forKey:NSFontAttributeName];
    [textAttr setObject:[NSColor whiteColor]
            forKey:NSForegroundColorAttributeName];

    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowOffset:NSMakeSize(2, -2)];
    [shadow setShadowBlurRadius:3];
    [shadow setShadowColor:[NSColor blackColor]];
    [textAttr setObject:shadow forKey:NSShadowAttributeName];
    
    NSNotificationCenter *ns =
            [[NSWorkspace sharedWorkspace] notificationCenter];
    [ns addObserver:self selector:@selector(_launchedAppStatusChanged:)
            name:NSWorkspaceDidLaunchApplicationNotification
            object:nil];
    [ns addObserver:self selector:@selector(_launchedAppStatusChanged:)
            name:NSWorkspaceDidTerminateApplicationNotification
            object:nil];
    
    contextMenu = [[NSMenu alloc] initWithTitle:@"AppSwitch Menu"];
    [contextMenu addItemWithTitle:NSLocalizedString(@"Show", @"")
            action:@selector(showSelectedApp:) keyEquivalent:@""];
    [contextMenu addItemWithTitle:NSLocalizedString(@"Hide", @"")
            action:@selector(hideSelectedApp:) keyEquivalent:@""];
    [contextMenu addItemWithTitle:NSLocalizedString(@"Hide Others", @"")
            action:@selector(hideOtherApps:) keyEquivalent:@""];
    [contextMenu addItem:[NSMenuItem separatorItem]];
    [contextMenu addItemWithTitle:NSLocalizedString(@"Quit", @"")
            action:@selector(quitSelectedApp:) keyEquivalent:@""];

    return self;
}

- (void)dealloc
{
    NSNotificationCenter *ns =
            [[NSWorkspace sharedWorkspace] notificationCenter];
    [ns removeObserver:self];

    [textAttr release];
    [runningApps release];
    [contextMenu release];
	[super dealloc];
}

- (void)awakeFromNib
{
    [[self window] setAcceptsMouseMovedEvents:YES];
    [self _launchedAppStatusChanged:nil];
}

- (void)drawRect:(NSRect)rect
{
    BOOL needsRedisplay = NO;
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    
    NSGraphicsContext *gc = [NSGraphicsContext currentContext];
    [gc setImageInterpolation:NSImageInterpolationHigh];
    
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSRect bounds = [self bounds];
    const float r = 10.0;
    
    // Draw a rounded-rect, but not filled at this time
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.3] set];
    [path moveToPoint:
            NSMakePoint(bounds.origin.x + r, bounds.origin.y + r)];
    [path relativeLineToPoint:NSMakePoint(bounds.size.width - 2*r, 0)];
    [path relativeLineToPoint:NSMakePoint(0, bounds.size.height - 2*r)];
    [path relativeLineToPoint:NSMakePoint(-bounds.size.width + 2*r, 0)];
    [path closePath];
    [path setLineWidth:r];
    [path setLineJoinStyle:NSRoundLineJoinStyle];
    [path stroke];

    // Fill the interior of the rect
    NSRectFill(NSMakeRect(bounds.origin.x + r,
                            bounds.origin.y + r,
                            bounds.origin.x + bounds.size.width - 2*r,
                            bounds.origin.y + bounds.size.height - 2*r));
    
    // Do process icons when the view is hidden
    if (!runningApps) return;
    
    int appCount = [runningApps count];
    int iter, idx = 0;
    float zoomStep = (now - drawTimestamp) / AppSwitchZoomDuration;
    if (selectedAppDict) {
        idx = [runningApps indexOfObject:selectedAppDict];
    }
    for (iter = 0; iter < appCount; iter++) {
        // Selected item must be drawn very last...
        idx = (idx + 1) % appCount;
        
        NSMutableDictionary *appDict;
        NSImage *appIcon;
        float thisIconSize;
        float zoomFactor;
        appDict = [runningApps objectAtIndex:idx];

        NSPoint iconCenter =
                [[appDict objectForKey:@"IconCenter"] pointValue];
        NSRect iconRect =
                [[appDict objectForKey:@"IconRect"] rectValue];
        
        zoomFactor = [[appDict objectForKey:@"ZoomFactor"] floatValue];
        if (appDict == selectedAppDict) {
            if (zoomFactor < 1.0) zoomFactor += zoomStep;
            if (zoomFactor < 1.0) needsRedisplay = YES;
            if (zoomFactor > 1.0) zoomFactor = 1.0;
        } else {
            if (zoomFactor > 0.0) zoomFactor -= zoomStep;
            if (zoomFactor > 0.0) needsRedisplay = YES;
            if (zoomFactor < 0.0) zoomFactor = 0.0;
        }
        [appDict setObject:[NSNumber numberWithFloat:zoomFactor]
                forKey:@"ZoomFactor"];

        thisIconSize = iconRect.size.width
                + (AppSwitchMaxIconSize - iconRect.size.width)
                * zoomFactor;
        NSRect iconRepRect = NSMakeRect(
                iconCenter.x - thisIconSize/2,
                iconCenter.y - thisIconSize/2,
                thisIconSize, thisIconSize);

        appIcon = [appDict objectForKey:@"AppIcon"];
        [appIcon setScalesWhenResized:YES];
        [appIcon setSize:iconRepRect.size];
        [appIcon compositeToPoint:iconRepRect.origin
                operation:NSCompositeSourceOver];
        /*NSLog(@"appName=%@ zoomFactor=%f thisIconSize=%f",
                [appDict objectForKey:@"NSApplicationName"],
                zoomFactor, thisIconSize);*/
    }
    
    if (selectedAppDict) {
        NSString *appName =
                [selectedAppDict objectForKey:@"NSApplicationName"];
        NSSize strSize = [appName sizeWithAttributes:textAttr];
        NSRect captRect = NSMakeRect(
                bounds.origin.x,
                bounds.origin.y + bounds.size.height/2
                    - strSize.height/2,
                bounds.size.width,
                strSize.height);
        [appName drawInRect:captRect withAttributes:textAttr];
    }
    
    drawTimestamp = now;
    if (needsRedisplay) {
        [NSTimer
                scheduledTimerWithTimeInterval:AppSwitchZoomDrawInterval
                target:self
                selector:@selector(_redisplayByTimer:userInfo:)
                userInfo:nil
                repeats:NO];
    }
}

- (void)_redisplayByTimer:(NSTimer *)aTimer userInfo:userInfo
{
    [self setNeedsDisplay:YES];
}

- (void)mouseMoved:(NSEvent *)event
{
    NSMutableDictionary *dict = [self _selectedApp:event];
    if (dict == selectedAppDict) return;
    
    selectedAppDict = dict;
    drawTimestamp = [NSDate timeIntervalSinceReferenceDate];
    [self setNeedsDisplay:YES];

    if (selectedAppDict)
        [self setMenu:contextMenu];
    else
        [self setMenu:nil];
}

- (void)mouseDown:(NSEvent *)event
{
    NSLog(@"clicked app=%@",
            [selectedAppDict objectForKey:@"NSApplicationName"]);
    [self showSelectedApp:nil];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (ProcessSerialNumber)_selectedAppPSN
{
    ProcessSerialNumber psn;
    psn.highLongOfPSN =
            [[selectedAppDict
                objectForKey:@"NSApplicationProcessSerialNumberHigh"]
                unsignedLongValue];
    psn.lowLongOfPSN =
            [[selectedAppDict
                objectForKey:@"NSApplicationProcessSerialNumberLow"]
                unsignedLongValue];
    return psn;
}

- (void)showSelectedApp:sender
{
    if (!selectedAppDict) {
        [NSApp deactivate];
        SetFrontProcessWithOptions(&frontProcess, kSetFrontProcessFrontWindowOnly);
        return;
    }
    
    // Create new document if none
    if (createsNewDocumentIfNone) {
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        NSString *targetApp =
                [selectedAppDict objectForKey:@"NSApplicationPath"];
        [ws launchApplication:targetApp];
    }

    // Bring all windows to the front
    OptionBits option = bringsAllWindowsToFront ?
            0 : kSetFrontProcessFrontWindowOnly;
    ProcessSerialNumber psn = [self _selectedAppPSN];
    SetFrontProcessWithOptions(&psn, option);
}

- (void)hideSelectedApp:sender
{
    [NSApp hide:self];
    if (!selectedAppDict) return;

    ProcessSerialNumber psn = [self _selectedAppPSN];
    ShowHideProcess(&psn, NO);
}

- (void)hideOtherApps:sender
{
    [NSApp hide:self];
    if (!selectedAppDict) return;

    [self showSelectedApp:sender];
    
    ProcessSerialNumber psn = {kNoProcess, kNoProcess};
    ProcessSerialNumber showPsn = [self _selectedAppPSN];
    while (GetNextProcess(&psn) != procNotFound) {
        if (!PSNEqual(psn, showPsn)) ShowHideProcess(&psn, NO);
    }
}

- (void)quitSelectedApp:sender
{
    [NSApp hide:self];
    if (!selectedAppDict) return;

    // Send fuckin' AplleEvent to the target App to quit
    ProcessSerialNumber psn = [self _selectedAppPSN];
    AEDesc appAddress;
    AppleEvent quitEvent, replyEvent;
    AECreateDesc(typeProcessSerialNumber, 
            (Ptr)&psn, 
            sizeof(ProcessSerialNumber), 
            &appAddress);
    AECreateAppleEvent(kCoreEventClass, 
            kAEQuitApplication, 
            &appAddress, 
            kAutoGenerateReturnID, 
            kAnyTransactionID, 
            &quitEvent);
    AESend(&quitEvent, &replyEvent, kAENoReply+kAENeverInteract,
            kAENormalPriority,
            kAEDefaultTimeout, nil, nil);
    AEDisposeDesc(&quitEvent);
    AEDisposeDesc(&appAddress);
}

- (BOOL)bringsAllWindowsToFront
{
    return bringsAllWindowsToFront;
}

- setBringsAllWindowsToFront:(BOOL)flag
{
    bringsAllWindowsToFront = flag;
    return self;
}

- (BOOL)createsNewDocumentIfNone
{
    return createsNewDocumentIfNone;
}

- setCreatesNewDocumentIfNone:(BOOL)flag
{
    createsNewDocumentIfNone = flag;
    return self;
}

- setFrontProcess:(ProcessSerialNumber)psn
{
    frontProcess = psn;
    return self;
}

@end
