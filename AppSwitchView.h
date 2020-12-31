/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Cocoa/Cocoa.h>

#define AppSwitchMenuRadius 128
#define AppSwitchBaseIconSize 80 
#define AppSwitchMaxIconSize 96
#define AppSwitchZoomDuration 0.1f
#define AppSwitchZoomDrawInterval (NSTimeInterval)(1/30.0f)
#define AppSwitchCaptionFontSize 18

@interface AppSwitchView : NSView
{
    BOOL bringsAllWindowsToFront;
    BOOL createsNewDocumentIfNone;

    NSMutableArray *runningApps;
    NSMutableDictionary *selectedAppDict;
    NSMutableDictionary *textAttr;
    NSMenu *contextMenu;
    NSTimeInterval drawTimestamp;
    ProcessSerialNumber frontProcess;
    
    float iconSize;
}

- initWithFrame:(NSRect)frameRect;
- (void)dealloc;

- (void)awakeFromNib;

- (void)drawRect:(NSRect)rect;
- (void)mouseMoved:(NSEvent *)event;
- (void)mouseDown:(NSEvent *)event;
- (BOOL)acceptsFirstResponder;

- (void)showSelectedApp:sender;
- (void)hideSelectedApp:sender;
- (void)hideOtherApps:sender;
- (void)quitSelectedApp:sender;

- (BOOL)bringsAllWindowsToFront;
- setBringsAllWindowsToFront:(BOOL)flag;
- (BOOL)createsNewDocumentIfNone;
- setCreatesNewDocumentIfNone:(BOOL)flag;
- setFrontProcess:(ProcessSerialNumber)psn;

@end
