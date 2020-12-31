/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import "HIDElement.h"
#import "HIDDevice.h"

@implementation HIDElement

+ elementWithDevice:(HIDDevice *)dev cookie:(IOHIDElementCookie)ck
{
    return [[[HIDElement alloc] initWithDevice:dev cookie:ck] autorelease];
}

- initWithDevice:(HIDDevice *)dev cookie:(IOHIDElementCookie)ck;
{
    [super init];
    hidDevice = dev;	// reference only - don't release
    cookie = ck;
    value = 0;
    return self;
}

@end
