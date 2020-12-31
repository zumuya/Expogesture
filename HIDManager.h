/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Foundation/Foundation.h>

#import "HIDDevice.h"
#import "HIDElement.h"

@interface HIDManager : NSObject
{
    io_iterator_t deviceIter;
    SEL deviceAddedCallbackSelector;
    id deviceAddedCallbackTarget;
}

+ (void)initialize;
+ (mach_port_t)masterPort;
+ (IONotificationPortRef)notifyPort;

- initWithDeviceAttachedCallbackSelector:(SEL)sel target:target
        forPrimaryUsagePage:(UInt32)usagePage usage:(UInt32)usage;

- (SEL)deviceAddedCallbackSelector;
- deviceAddedCallbackTarget;

@end
