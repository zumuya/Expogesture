/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <AppKit/AppKit.h>

@class HotkeyEvent;

@interface HotkeyCapture : NSView {
    HotkeyEvent *hotkey;
    
    NSDictionary *textAttr;
    BOOL _enabled;
}

- (void)setEnabled:(BOOL)flag;

- (HotkeyEvent *)hotkey;
- (void)setHotkey:(HotkeyEvent *)newHotkey;

@end
