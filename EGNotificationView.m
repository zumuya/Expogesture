/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import "EGNotificationView.h"

@implementation EGNotificationView

- (id)initWithFrame:(NSRect)frameRect
{
	[super initWithFrame:frameRect];
	return self;
}

- (void)drawRect:(NSRect)rect
{
    NSBezierPath *path = [NSBezierPath bezierPath];
    NSRect frame = [self frame];
    const float r = 10.0;
    
    // First, background should be cleared to transparent - really?
    //[[NSColor colorWithDeviceWhite:0.0 alpha:0.0] set];
    //NSRectFill([self frame]);

    // Draw a rounded-rect, but not filled at this time
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.3] set];
    [path moveToPoint:NSMakePoint(frame.origin.x + r, frame.origin.y + r)];
    [path relativeLineToPoint:NSMakePoint(frame.size.width - 2*r, 0)];
    [path relativeLineToPoint:NSMakePoint(0, frame.size.height - 2*r)];
    [path relativeLineToPoint:NSMakePoint(-frame.size.width + 2*r, 0)];
    [path closePath];
    [path setLineWidth:r];
    [path setLineJoinStyle:NSRoundLineJoinStyle];
    [path stroke];

    // Fill the interior of the rect
    NSRectFill(NSMakeRect(frame.origin.x + r,
                            frame.origin.y + r,
                            frame.origin.x + frame.size.width - 2*r,
                            frame.origin.y + frame.size.height - 2*r));
    
    //[super drawRect:rect];
}


- (NSAttributedString *)attributedStringValue
{
	return [notificationLabel attributedStringValue];
}


- setText:(NSString *)text
{
	[notificationLabel setStringValue:text];
    return self;
}

@end
