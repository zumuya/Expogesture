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
			propertyListForType:NSPasteboardTypeFileURL];
	NSEnumerator *anEnum = [fileList objectEnumerator];
	NSURL *url;
	BOOL containsApps = NO;
	while (url = [anEnum nextObject]) {
		BOOL isApp = FALSE;
		NSBundle *bundle = [NSBundle bundleWithURL: url];
		if (bundle) {
			isApp = [[bundle objectForInfoDictionaryKey:
					@"CFBundlePackageType"] isEqualToString:@"APPL"];
		} else {
			NSDictionary *fileAttr = [fm attributesOfItemAtPath: url.path error: NULL];
			isApp = [[fileAttr objectForKey:NSFileHFSTypeCode]
					unsignedLongValue];
		}
		if (isApp) {
			containsApps = YES;
			[(id <EGAppTableViewDelegate>)[self delegate]
					appTableView:self addApplicationPath:url.path];
		}
	}
	return containsApps;
}

- (void)concludeDragOperation:sender
{
	// nop
}

@end
