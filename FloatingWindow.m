/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import "FloatingWindow.h"
#import "NSScreen-EGExt.h"

@implementation FloatingWindow

- initWithContentRect:(NSRect)contentRect
        styleMask:(unsigned int)styleMask
        backing:(NSBackingStoreType)backingType
        defer:(BOOL)flag
{
    [super initWithContentRect:contentRect
        styleMask:NSBorderlessWindowMask //styleMask
        backing:backingType
        defer:flag];
    return self;
}

- (void)awakeFromNib
{
    [self setBackgroundColor:[NSColor clearColor]];
    [self setOpaque:NO];
    [self setHasShadow:NO];
    [self setLevel:NSFloatingWindowLevel];
    [self setCanHide:NO];
}

- setFrameCenteredAt:(NSPoint)center
{
    NSRect screen = [[NSScreen screenUnderMouse] frame];
    NSRect myFrame = [self frame];
    myFrame.origin = NSMakePoint(
            center.x - myFrame.size.width/2,
            center.y - myFrame.size.height/2);

    if (myFrame.origin.x < screen.origin.x)
        myFrame.origin.x = screen.origin.x;
    if (myFrame.origin.y < screen.origin.y)
        myFrame.origin.y = screen.origin.y;
    if (NSMaxX(myFrame) > NSMaxX(screen))
        myFrame.origin.x = NSMaxX(screen) - myFrame.size.width;
    if (NSMaxY(myFrame) > NSMaxY(screen))
        myFrame.origin.y = NSMaxY(screen) - myFrame.size.height;

    [self setFrameOrigin:myFrame.origin];
    return self;
}

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (void)becomeKeyWindow
{
    [super becomeKeyWindow];
    [self setIgnoresMouseEvents:NO];
}

- (void)resignKeyWindow
{
    [super resignKeyWindow];
    [self setIgnoresMouseEvents:YES];
    [self orderOutWithFade:self];
}

- (void)_fadeOut:(NSTimer *)timer userInfo:userInfo
{
    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    float alpha = 1.0 -
            (now - faderStartTimestamp) / FloatingWindowFaderDuration;

    if (alpha <= 0.0) {
        [self orderOut:self];
        [self setAlphaValue:1.0];
        [timer invalidate];
    } else {
        [self setAlphaValue:alpha];
        /*
        [self performSelector:@selector(_fadeOut)
                withObject:nil
                afterDelay:FloatingWindowFaderRedrawInterval];
        */
    }
}

- orderOutWithFade:sender
{
    faderStartTimestamp = [NSDate timeIntervalSinceReferenceDate];
    fadeoutTimer = [NSTimer
            scheduledTimerWithTimeInterval:FloatingWindowFaderRedrawInterval
            target:self
            selector:@selector(_fadeOut:userInfo:)
            userInfo:nil
            repeats:YES];
    //[self _fadeOut];
    return self;
}

@end
