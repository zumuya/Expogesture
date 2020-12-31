/*
	Copyright (C) 2003-2004 NAKAHASHI Ichiro, (C) 2020-2021 zumuya

	This program is distributed under the GNU Public License.
	This program comes with NO WARRANTY.
*/

#import "NotificationWindowController.h"
#import "FloatingWindow.h"
#import "NSScreen-EGExt.h"

@interface NotificationBackgroundView: NSView
@end

@implementation NotificationBackgroundView

-(BOOL)wantsUpdateLayer { return true; }
-(void)updateLayer
{
	[super updateLayer];
	[self.layer setBackgroundColor: [NSColor colorWithWhite: 0.2 alpha: 0.4].CGColor];
	[self.layer setCornerRadius: 16];
	if (@available(macOS 10.15, *)) {
		//[self.layer setCornerCurve: kCACornerCurveContinuous];
	}
}

@end

@implementation NotificationWindowController

static id _sharedController;
+(instancetype)sharedController
{
	return (_sharedController ? _sharedController : (_sharedController = [[self alloc] init]));
}

-(instancetype)init
{
	NSView* backgroundView = [[NotificationBackgroundView alloc] init];
	textLabel = [NSTextField labelWithString: @"a"]; {
		[textLabel setTranslatesAutoresizingMaskIntoConstraints: false];
		[textLabel setTextColor: NSColor.whiteColor];
		[textLabel setDrawsBackground: NO];
		[textLabel setFont: [NSFont systemFontOfSize: 32]];
		[textLabel setContentHuggingPriority: NSLayoutPriorityDefaultHigh forOrientation: NSLayoutConstraintOrientationHorizontal];
	}
	[backgroundView addSubview: textLabel];
	NSArray<NSLayoutConstraint*>* textLabelConstraints = @[
		[textLabel.centerXAnchor constraintEqualToAnchor: backgroundView.centerXAnchor],
		[textLabel.centerYAnchor constraintEqualToAnchor: backgroundView.centerYAnchor],
		[backgroundView.widthAnchor constraintEqualToAnchor: textLabel.widthAnchor constant: 40],
		[backgroundView.heightAnchor constraintEqualToAnchor: textLabel.heightAnchor constant: 20],
	];
	[backgroundView addConstraints: textLabelConstraints];
		
	NSViewController* viewController = [[NSViewController alloc] init]; {
		[viewController setView: backgroundView];
	}
	
	FloatingWindow* window = [FloatingWindow windowWithContentViewController: viewController]; {
		[window setStyleMask: NSWindowStyleMaskBorderless];
		[window setIgnoresMouseEvents: YES];
	}
	if (self = [super initWithWindow: window]) {
		
	}
	return self;
}

-(void)showWithText: (NSString*)text
{
	[textLabel setStringValue: text];
	[self show];
}

-(void)show
{
	// Notification window should not averlap mouse pointer...
	static NSPoint notifWindowPosList[] = {
		{0.5,  0.5 },   // center
		{0.25, 0.75},   // upper-right
		{0.75, 0.75},   // upper-left
		{0.25, 0.25},   // lower-right
		{0.75, 0.25},   // lower-left
	};
		
	NSRect screenFrame = NSScreen.screenUnderMouse.frame;

	self.window.contentMaxSize = NSMakeSize((screenFrame.size.width / 2.2), 9999);
	[self.window layoutIfNeeded];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSInteger positionIndex = [defaults integerForKey: @"NotifWindowPosition"];
	NSPoint windowPositionFactor = notifWindowPosList[positionIndex];
	NSPoint windowPosition = screenFrame.origin; {
		windowPosition.x += (windowPositionFactor.x * screenFrame.size.width);
		windowPosition.y += (windowPositionFactor.y * screenFrame.size.height);
	}
	[(FloatingWindow*)self.window setFrameCenteredAt: windowPosition];
	
	[self.window orderFrontRegardless];

	[closingTimer invalidate];
	closingTimer = [NSTimer scheduledTimerWithTimeInterval: 0.4f target: self selector: @selector(dismissWithFade) userInfo: nil repeats: NO];
}

-(void)dismissWithFade
{
	[(FloatingWindow*)self.window orderOutWithFade: self];
	[closingTimer invalidate];
	closingTimer = nil;
}

@end
