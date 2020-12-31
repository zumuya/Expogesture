/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Cocoa/Cocoa.h>

#import <mach/mach.h>
#import <mach/mach_error.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/IOCFPlugIn.h>
#import <IOKit/IOMessage.h>
#import <IOKit/hid/IOHIDLib.h>
#import <IOKit/hid/IOHIDUsageTables.h>
#import <IOKit/usb/USB.h>

@interface HIDDevice : NSObject
{
    io_object_t myHIDDevice;
    IOHIDDeviceInterface **pphidDeviceInterface;
    IOHIDQueueInterface **queue;
    NSString *className;
    
@public
    io_object_t notification;
    SEL eventCallbackSelector;
    SEL removedCallbackSelector;
    id removedCallbackTarget;
}

+ deviceWithRawHIDDevice:(io_object_t)hidDevice;

- (id)initWithRawHIDDevice:(io_object_t)hidDevice;
- (void)dealloc;

- (NSString *)className;
- (NSDictionary *)properties;
- (IOHIDElementCookie)elementCookieForUsagePage:(UInt32)usagePage usage:(UInt32)usage;
- (long)elementValue:(IOHIDElementCookie)cookie;
- (HRESULT)queueAddElement:(IOHIDElementCookie)cookie;
- (HRESULT)nextEvent:(IOHIDEventStruct *)eventRef;
- setEventCallbackSelector:(SEL)sel target:target;
- setRemovedCallbackSelector:(SEL)sel target:target;

@end
