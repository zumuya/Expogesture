/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Cocoa/Cocoa.h>

@interface EGNotificationView : NSView
{
    IBOutlet NSTextField *notificationLabel;
}

- (NSAttributedString *)attributedStringValue;
- setText:(NSString *)text;

@end
