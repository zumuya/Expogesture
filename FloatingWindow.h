/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Cocoa/Cocoa.h>

#define FloatingWindowFaderDuration 0.2f
#define FloatingWindowFaderRedrawInterval (NSTimeInterval)(1/30.0f)

@class AppSwitchView;
@class WindowFader;

@interface FloatingWindow : NSWindow
{
    NSTimeInterval faderStartTimestamp;
    NSTimer *fadeoutTimer;
}

- initWithContentRect:(NSRect)contentRect
        styleMask:(unsigned int)styleMask
        backing:(NSBackingStoreType)backingType
        defer:(BOOL)flag;
- setFrameCenteredAt:(NSPoint)center;

- (BOOL)canBecomeKeyWindow;
- (void)becomeKeyWindow;
- (void)resignKeyWindow;
- orderOutWithFade:sender;

@end
