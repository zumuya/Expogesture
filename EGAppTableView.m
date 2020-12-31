/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import "EGAppTableView.h"

@implementation EGAppTableView

- (void)drawRect:(NSRect)aRect
{
    [super drawRect:aRect];
    
    if (isDraggingDestination) {
        NSBezierPath *bp = [NSBezierPath bezierPathWithRect:
                NSInsetRect([self bounds], 1, 1)];
        [[NSColor selectedControlColor] set];
        [bp setLineWidth:2];
        [bp stroke];
    }
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    isDraggingDestination = YES;
    [self setNeedsDisplay:YES];
    return NSDragOperationGeneric;    
}

-(NSDragOperation)draggingUpdated: (id <NSDraggingInfo>)sender
{
    return NSDragOperationGeneric;    
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
    isDraggingDestination = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)prepareForDragOperation:sender
{
    isDraggingDestination = NO;
    [self setNeedsDisplay:YES];
    return YES;
}

- (BOOL)performDragOperation:sender
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *fileList = [[sender draggingPasteboard]
            propertyListForType:NSFilenamesPboardType];
    NSEnumerator *anEnum = [fileList objectEnumerator];
    NSString *path;
    BOOL containsApps = NO;
    while (path = [anEnum nextObject]) {
        BOOL isApp = FALSE;
        NSBundle *bundle = [NSBundle bundleWithPath:path];
        if (bundle) {
            isApp = [[bundle objectForInfoDictionaryKey:
                    @"CFBundlePackageType"] isEqualToString:@"APPL"];
        } else {
            NSDictionary *fileAttr =
                    [fm fileAttributesAtPath:path traverseLink:YES];
            isApp = [[fileAttr objectForKey:NSFileHFSTypeCode]
                    unsignedLongValue];
        }
        if (isApp) {
            containsApps = YES;
            [(id <EGAppTableViewDelegate>)[self delegate]
                    appTableView:self addApplicationPath:path];
        }
    }
    return containsApps;
}

- (void)concludeDragOperation:sender
{
    // nop
}

@end
