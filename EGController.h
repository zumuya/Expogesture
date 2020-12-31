/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Cocoa/Cocoa.h>

@class EGPreference;
@class EGNotificationView;
@class FloatingWindow;
@class AppSwitchView;

@interface EGController : NSObject
{
    IBOutlet EGPreference *prefController;
    IBOutlet EGNotificationView *notifView;
    IBOutlet NSMenu *statusMenu;
    IBOutlet FloatingWindow *notifWindow;
    IBOutlet FloatingWindow *appSwitchWindow;
    IBOutlet AppSwitchView *appSwitchView;
    
    NSMutableDictionary *eventKeyDefs;
    NSArray *keyDefsGlobal;
    BOOL usePollingToTrackPointer;
    unsigned long mouseMoveTimeout;
    float pointerPollingInterval;
    int gestureSizeMin;
    
    NSTimer *mousePollTimer;
    NSTimer *notifWindowTimer;
    NSMutableArray *hidDevices;
    NSMutableArray *mouseMoveXElements;
    NSMutableArray *mouseMoveYElements;
    NSPoint lastMousePoint;
    
    unsigned long lastMouseMoveTimestamp;
    float nowPhi, lastPhi, lastDPhi, lastSpeed;
    int currentDirection, currentRotation, motionAmount;
    float rotateAmount;
    int lastMove;
    unsigned long lastIssuedTimestamp, lastMoveTimestamp;
    int *gestureProgresses;
    BOOL sessionIsHidden;
    
    NSStatusItem *statusItem;
}

- (void)dealloc;

- (void)awakeFromNib;
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)applicationWillTerminate:(NSNotification *)aNotification;

- (void)showStatusBarMenu;
- (void)hideStatusBarMenu;
- (IBAction)showAboutPanel:sender;

- (NSMutableDictionary *)eventKeyDefs;
- (int)gestureSizeMin;
- setGestureSizeMin:(int)min;
- (AppSwitchView *)appSwitchView;

@end
