/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Cocoa/Cocoa.h>

#import "HIDDevice.h"

@interface HIDElement : NSObject
{
@public
    HIDDevice *hidDevice;
    IOHIDElementCookie cookie;
    long value;
}

+ elementWithDevice:(HIDDevice *)dev cookie:(IOHIDElementCookie)ck;

- initWithDevice:(HIDDevice *)dev cookie:(IOHIDElementCookie)ck;

@end
