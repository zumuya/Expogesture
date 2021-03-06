/*
	Copyright (C) 2003-2004 NAKAHASHI Ichiro

	This program is distributed under the GNU Public License.
	This program comes with NO WARRANTY.
*/

#import <Carbon/Carbon.h>
#import "HotkeyCapture.h"
#import "HotkeyEvent.h"

typedef int CGSConnection;
typedef enum {
	CGSGlobalHotKeyEnable = 0,
	CGSGlobalHotKeyDisable = 1,
} CGSGlobalHotKeyOperatingMode;
extern CGSConnection _CGSDefaultConnection(void);
extern CGError CGSGetGlobalHotKeyOperatingMode(CGSConnection connection, CGSGlobalHotKeyOperatingMode *mode);
extern CGError CGSSetGlobalHotKeyOperatingMode(CGSConnection connection, CGSGlobalHotKeyOperatingMode mode);


@implementation HotkeyCapture

- initWithFrame:(NSRect)frame
{
	self = [super initWithFrame:frame];
	hotkey = [[HotkeyEvent alloc] initWithKeyCode:0 ctrl:NO alt:NO cmd:NO];
	textAttr = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSFont systemFontOfSize:0], NSFontAttributeName,
		nil];
	_enabled = YES;
	return self;
}

- (BOOL)acceptsFirstResponder
{
	return YES;
}

- (void)drawRect:(NSRect)rect
{
	NSRect b = [self bounds];

	if (!_enabled) {
		NSDrawGrayBezel(b, b);
		return;
	}
	
	[NSGraphicsContext saveGraphicsState];
	if ([[self window] firstResponder] == self) {
		NSSetFocusRingStyle(NSFocusRingBelow);
	}
	NSDrawWhiteBezel(b, b);
	[NSGraphicsContext restoreGraphicsState];

	NSSize s = [[hotkey localizedDescription] sizeWithAttributes:textAttr];
	NSPoint p;
	p.x = b.origin.x + (b.size.width - s.width) / 2;
	p.y = b.origin.y + (b.size.height - s.height) / 2;
	[[hotkey localizedDescription] drawAtPoint:p withAttributes:textAttr];
}

- (BOOL)becomeFirstResponder
{
	if (!_enabled) return NO;
	
	[self setNeedsDisplay:YES];
	CGSSetGlobalHotKeyOperatingMode(_CGSDefaultConnection(), CGSGlobalHotKeyDisable);
	
	NSEvent *event;
	unsigned int mod;
	while (TRUE) {
		event = [[self window] nextEventMatchingMask:NSEventMaskAny];
		switch ([event type]) {
		case NSEventTypeKeyDown:
			[hotkey setKeyCode:[event keyCode]];
			mod = [event modifierFlags];
			[hotkey setShift:(mod & NSEventModifierFlagShift) != 0];
			[hotkey setCtrl:(mod & NSEventModifierFlagControl) != 0];
			[hotkey setAlt:(mod & NSEventModifierFlagOption) != 0];
			[hotkey setCmd:(mod & NSEventModifierFlagCommand) != 0];
			goto finished;
		case NSEventTypeRightMouseDown:
		case NSEventTypeLeftMouseDown:
			[[self window] postEvent:event atStart:YES];
			goto finished;
		default:
			break;
		}
	}

finished:
	[self setNeedsDisplay:YES];
	//[[self window] selectNextKeyView:self];
	[[self window] makeFirstResponder:[self nextKeyView]];
	return YES;
}
	
- (BOOL)resignFirstResponder
{
	[self setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
	CGSSetGlobalHotKeyOperatingMode(
			_CGSDefaultConnection(), CGSGlobalHotKeyEnable);
	return YES;
}

- (void)setEnabled:(BOOL)flag
{
	_enabled = flag;
	[self setNeedsDisplay:YES];
}

- (HotkeyEvent *)hotkey
{
	return hotkey;
}

- (void)setHotkey:(HotkeyEvent *)newHotkey
{
	hotkey = newHotkey;
	[self setNeedsDisplay:YES];
}

@end
