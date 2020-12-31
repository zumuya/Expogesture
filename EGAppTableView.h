/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Cocoa/Cocoa.h>

@interface EGAppTableView : NSTableView
{
    BOOL isDraggingDestination;
}

- (void)drawRect:(NSRect)aRect;

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender;
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;
- (void)draggingExited:(id <NSDraggingInfo>)sender;
- (BOOL)prepareForDragOperation:sender;
- (BOOL)performDragOperation:sender;
- (void)concludeDragOperation:sender;

@end

@protocol EGAppTableViewDelegate
- (void)appTableView:(EGAppTableView *)view
        addApplicationPath:(NSString *)path;
@end
