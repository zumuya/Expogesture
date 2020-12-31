/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Cocoa/Cocoa.h>

struct hotkeyDef_t {
    NSString *keyName;
    CGCharCode charCode;
    CGKeyCode keyCode;
    BOOL needShift;
    BOOL canShift;
};
extern struct hotkeyDef_t hotkeyDefs[];
extern int hotkeyDefsCount;

typedef enum _HotkeyPseudoEventType {
    HotkeyInherit = -1,
    HotkeyDisabled = 0,
    HotkeyNormalEvent,
    HotkeyAppSwitch,
	HotkeyMenuItem,
} HotkeyPseudoEventType;

@interface HotkeyEvent : NSObject <NSCopying>
{
    NSString *keyName;
    BOOL ctrl;
    BOOL alt;
    BOOL cmd;
    BOOL shift;
    BOOL canShift;
    CGCharCode charCode;
    CGKeyCode keyCode;
    HotkeyPseudoEventType pseudoEventType;
	NSString *menuLabel;
	
	// attributes below are temporal; not archived into dictionary
	pid_t _pidCache;
	id _menuItemRefCache;	// AXUIElementRef
}

+ (NSArray *)arrayOfKeyNames;
+ (NSArray *)arrayOfLocalizedKeyNames;
+ (NSString *)keyNameAtIndex:(int)index;
+ (int)indexOfKeyName:(NSString *)keyName;
+ (NSArray *)hotkeyArrayWithArray:(NSArray *)anArray
        count:(int)count global:(BOOL)gFlag;

- (HotkeyEvent *)initWithKeyName:(NSString *)keyName
        ctrl:(BOOL)ctrlFlag alt:(BOOL)altFlag cmd:(BOOL)cmdFlag;
- (void)dealloc;
- initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionary;
- copyWithZone:(NSZone *)zone;

- (NSString *)keyName;
- (CGCharCode)charCode;
- (CGKeyCode)keyCode;
- (BOOL)ctrl;
- (BOOL)alt;
- (BOOL)cmd;
- (BOOL)shift;
- (id)setKeyName:(NSString *)keyName;
- setKeyCode:(CGKeyCode)keyCode;
- (id)setCtrl:(BOOL)flag;
- (id)setAlt:(BOOL)flag;
- (id)setCmd:(BOOL)flag;
- (id)setShift:(BOOL)flag;
- (BOOL)isAlphabet;
- (BOOL)canShift;
- (NSString *)localizedDescription;

- (HotkeyPseudoEventType)pseudoEventType;
- setPseudoEventType:(HotkeyPseudoEventType)eventType;

- (NSString *)menuLabel;
- setMenuLabel:(NSString *)newLabel;

- (pid_t)pidCache;
- setPidCache:(pid_t)pid;
- (AXUIElementRef)menuItemRefCache;
- setMenuItemRefCache:(AXUIElementRef)menuItemRef;

@end
