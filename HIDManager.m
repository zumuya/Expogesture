/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import "HIDManager.h"

static mach_port_t masterPort = nil;
static IONotificationPortRef notifyPort = nil;
static CFRunLoopSourceRef runLoopSrcRef;
static CFRunLoopRef runLoopRef;

static void deviceAddedCallbackStub(void *refCon, io_iterator_t iterator)
{
    HIDManager *self = refCon;
    NSMutableArray *devArray = [NSMutableArray array];
    io_object_t hidDevice;
    
    while (hidDevice = IOIteratorNext(iterator)) {
        [devArray addObject:[HIDDevice deviceWithRawHIDDevice:hidDevice]];
    }
    [[self deviceAddedCallbackTarget]
            performSelector:[self deviceAddedCallbackSelector]
            withObject:devArray];
}

@implementation HIDManager

+ (void)initialize
{
    kern_return_t kRet;

    if (masterPort != nil) return;

    kRet = IOMasterPort(bootstrap_port, &masterPort);
    if (kRet != kIOReturnSuccess) {
        NSLog(@"HIDManager - Couldn't create a master I/O Kit Port.");
        exit(1);
    }
    NSLog(@"HIDManager - mach master port = %d", masterPort);
    
    // masterPort should be freed when the application terminates, but I do not know
    // how...
}

+ (mach_port_t)masterPort
{
    return masterPort;
}

+ (IONotificationPortRef)notifyPort
{
    return notifyPort;
}

- (void)setupNotifyPort
{
    if (notifyPort != nil) return;
    
    notifyPort = IONotificationPortCreate(masterPort);
    runLoopSrcRef = IONotificationPortGetRunLoopSource(notifyPort);
    runLoopRef = [[NSRunLoop currentRunLoop] getCFRunLoop];
    CFRunLoopAddSource(runLoopRef, runLoopSrcRef, kCFRunLoopDefaultMode);
    
}

- initWithDeviceAttachedCallbackSelector:(SEL)sel target:target
        forPrimaryUsagePage:(UInt32)usagePage usage:(UInt32)usage
{
    NSMutableDictionary *hidMatchDict;
    kern_return_t kr;
    
    [self setupNotifyPort];
    
    deviceAddedCallbackSelector = sel;
    deviceAddedCallbackTarget = target;
    
    hidMatchDict = (NSMutableDictionary *)IOServiceMatching(kIOHIDDeviceKey);
    if (hidMatchDict == nil) {
        NSLog(@"HIDDevice - IOServiceMatching failed.");
        return nil;
    }
    [hidMatchDict
            setObject:[NSNumber numberWithInt:usagePage]
            forKey:[NSString stringWithCString:kIOHIDPrimaryUsagePageKey]];
    [hidMatchDict
            setObject:[NSNumber numberWithInt:usage]
            forKey:[NSString stringWithCString:kIOHIDPrimaryUsageKey]];

    // Now set up a notification to be called when a device is first matched by I/O Kit.
    kr = IOServiceAddMatchingNotification(
            notifyPort,   		// notifyPort
            kIOFirstMatchNotification,	// notificationType
            (CFDictionaryRef)hidMatchDict,	// matching
            deviceAddedCallbackStub,	// callback
            self,			// refCon
            &deviceIter			// notification
            );  
                                            
    // Iterate once to get already-present devices and arm the notification    
    deviceAddedCallbackStub(self, deviceIter); 
    
    return self;
}

- (SEL)deviceAddedCallbackSelector
{
    return deviceAddedCallbackSelector;
}

- deviceAddedCallbackTarget
{
    return deviceAddedCallbackTarget;
}

@end
