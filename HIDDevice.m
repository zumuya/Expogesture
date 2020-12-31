/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import "HIDDevice.h"
#import "HIDManager.h"

static IOHIDElementCookie searchForCookie(
        NSArray *array, UInt32 usagePage, UInt32 usage)
{
    int idx;
    id prop, child;
    IOHIDElementCookie cookie;
    
    for (idx = 0; idx < [array count]; idx++) {
        prop = [array objectAtIndex:idx];
        
        child = [prop objectForKey:[NSString stringWithCString:kIOHIDElementKey]];
        if (child) {
            cookie = searchForCookie(child, usagePage, usage);
            if (cookie) return cookie;
        }
        
        child = [prop objectForKey:[NSString stringWithCString:kIOHIDElementUsagePageKey]];
        if (!child || [child intValue] != usagePage) continue;
        
        child = [prop objectForKey:[NSString stringWithCString:kIOHIDElementUsageKey]];
        if (!child || [child intValue] != usage) continue;
        
        child = [prop objectForKey:[NSString stringWithCString:kIOHIDElementCookieKey]];
        return (IOHIDElementCookie)[child intValue];
    }
    return 0;	// not found
}

static void eventCallbackStub(void *device, IOReturn result, void *target, void *sender)
{
    HIDDevice *self = device;
    [(NSObject *)target
            performSelector:self->eventCallbackSelector
            withObject:(NSObject *)self];
    result = kIOReturnSuccess;	// ???
}

static void removedCallbackStub(void *refCon, io_service_t service,
        natural_t messageType, void *messageArgument)
{
    HIDDevice *self = refCon;
    
    if (messageType != kIOMessageServiceIsTerminated) return;
    
    [self->removedCallbackTarget
            performSelector:self->removedCallbackSelector
            withObject:self];
    IOObjectRelease(self->notification);
}


@implementation HIDDevice

+ deviceWithRawHIDDevice:(io_object_t)hidDevice
{
    HIDDevice *newObj = [[HIDDevice alloc] initWithRawHIDDevice:hidDevice];
    return [newObj autorelease];
}

- (id)initWithRawHIDDevice:(io_object_t)hidDevice
{
    io_name_t name;
    IOCFPlugInInterface **plugInInterface = NULL;
    HRESULT hwRet;
    SInt32 score = 0;
    kern_return_t kRet;
    
    [super init];
    myHIDDevice = hidDevice;

    kRet = IOObjectGetClass(myHIDDevice, name);
    if (kRet != kIOReturnSuccess) {
        NSLog(@"HIDDevice - Failed to get class name.");
        goto fail;
    }
    className = [[NSString alloc] initWithCString:name];
    NSLog(@"HIDDevice - Creating interface for device of class %@", className);
    kRet = IOCreatePlugInInterfaceForService (
                myHIDDevice,
                kIOHIDDeviceUserClientTypeID,
                kIOCFPlugInInterfaceID,
                &plugInInterface, &score);
    if (kRet != kIOReturnSuccess) {
        NSLog(@"HIDDevice - IOCreatePlugInInterfaceForService failed.");
        goto fail;
    }
    hwRet = (*plugInInterface)->QueryInterface(
                            plugInInterface,
                            CFUUIDGetUUIDBytes(kIOHIDDeviceInterfaceID),
                            (void *)&pphidDeviceInterface);
    if (hwRet != S_OK) {
        NSLog(@"HIDDevice - Couldn't query HID class device interface from plugInInterface");
        goto fail;
    }
    (*plugInInterface)->Release(plugInInterface);

    kRet = (*pphidDeviceInterface)->open(pphidDeviceInterface, 0);
    if (kRet != kIOReturnSuccess) {
        NSLog(@"HIDDevice - Could not open device interface.");
        goto fail;
    }

    queue = (*pphidDeviceInterface)->allocQueue(pphidDeviceInterface);
    if (!queue) {
        NSLog(@"HIDDevice - Could not alloc device queue.");
        goto fail;
    }
    hwRet = (*queue)->create(queue, 0, 8);

    // Register notification callback handler for device removal
    kRet = IOServiceAddInterestNotification(
            [HIDManager notifyPort],	// notifyPort
            myHIDDevice,		// service
            kIOGeneralInterest,		// interestType
            removedCallbackStub,	// callback
            self,			// refCon
            &notification		// notification
            );
    if (KERN_SUCCESS != kRet)
        NSLog(@"IOServiceAddInterestNotification returned %08x", kRet);

    return self;
    
fail:
    pphidDeviceInterface = nil;
    [self release];
    return nil;
}

- (void)dealloc
{
    NSLog(@"HIDDevice - Releasing interface for device class %@", className);
    if (queue) {
        (*queue)->stop(queue);
        (*queue)->dispose(queue);
        (*queue)->Release(queue);
    }
    if (pphidDeviceInterface) {
        (*pphidDeviceInterface)->Release(pphidDeviceInterface);
    }
    [className release];
    [super dealloc];
}

- (NSString *)className
{
    return className;
}

- (NSDictionary *)properties
{
    kern_return_t res;
    NSMutableDictionary *prop = nil;
    
    res = IORegistryEntryCreateCFProperties(
                myHIDDevice,
                (CFMutableDictionaryRef *)&prop,
                kCFAllocatorDefault, kNilOptions);
    if (res != KERN_SUCCESS || prop == nil) {
        NSLog(@"HIDDeivce - IORegistryEntryCreateCFProperties failed.");
        return nil;
    }
    
    return [prop autorelease];
}

- (IOHIDElementCookie)elementCookieForUsagePage:(UInt32)usagePage usage:(UInt32)usage
{
    NSDictionary *prop = [self properties];
    return searchForCookie(
            [prop objectForKey:[NSString stringWithCString:kIOHIDElementKey]],
            usagePage, usage);
}

- (long)elementValue:(IOHIDElementCookie)cookie
{
    HRESULT rc;
    IOHIDEventStruct hidEvent;
    
    rc = (*pphidDeviceInterface)->getElementValue(
                pphidDeviceInterface,
                cookie,
                &hidEvent);
    if (rc) {
        NSLog(@"HIDDevice - getElementValue failed. code = %d", rc);
        return -1;
    }
    return hidEvent.value;
}

- (HRESULT)queueAddElement:(IOHIDElementCookie)cookie
{
    HRESULT hwRet;
    hwRet = (*queue)->addElement(queue, cookie, 0);
    return hwRet;
}

- (HRESULT)nextEvent:(IOHIDEventStruct *)eventRef
{
    static const AbsoluteTime zeroTime = {0,0};
    HRESULT hwRet;
    hwRet = (*queue)->getNextEvent(queue, eventRef, zeroTime, 0);
    return hwRet;
}

- (SEL)eventCallbackSelector
{
    return eventCallbackSelector;
}

- setEventCallbackSelector:(SEL)sel target:target
{
    HRESULT hwRet;
    CFRunLoopRef runLoopRef = [[NSRunLoop currentRunLoop] getCFRunLoop];
    CFRunLoopSourceRef runLoopSrcRef;
    
    eventCallbackSelector = sel;
    
    hwRet = (*queue)->createAsyncEventSource(queue, &runLoopSrcRef);
    if (kIOReturnSuccess != hwRet)
        NSLog(@"Failed to createAsyncEventSource, error: %ld.", hwRet);

    // if we have one nowÉ
    if (NULL != runLoopSrcRef)
    {
        // and it's not already attached to our runloopÉ
        if (!CFRunLoopContainsSource(runLoopRef,
                    runLoopSrcRef, kCFRunLoopDefaultMode))
            // then attach it now.
            CFRunLoopAddSource(runLoopRef, runLoopSrcRef, kCFRunLoopDefaultMode);
    }

    // now install our callback
    hwRet = (*queue)->setEventCallout(queue, eventCallbackStub, self, target);
    if (kIOReturnSuccess != hwRet)
        NSLog(@"Failed to setEventCallout, error: %ld.", hwRet);

    //start data delivery to queue
    hwRet = (*queue)->start(queue);
    NSLog(@"HIDDevice - queue has been created. result=%lx", hwRet);
    
    return self;
}

- setRemovedCallbackSelector:(SEL)sel target:target
{
    removedCallbackSelector = sel;
    removedCallbackTarget = target;
    return self;
}

@end
