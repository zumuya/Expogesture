/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Carbon/Carbon.h>
#import "HotkeyEvent.h"

// NOTE: We seems to have to send Shift-Key-Pressed and -Release
// events before and after some symbols, such as '?' and '|'.
// Those actions might depend on each keymap and it will not work
// correctly on non-Japanese systems.

struct hotkeyDef_t hotkeyDefs[] = {
    { @"A",		'A',	0,	NO,	YES	},
    { @"B",		'B',	11,	NO,	YES	},
    { @"C",		'C',	8,	NO,	YES	},
    { @"D",		'D',	2,	NO,	YES	},
    { @"E",		'E',	14,	NO,	YES	},
    { @"F",		'F',	3,	NO,	YES	},
    { @"G",		'G',	5,	NO,	YES	},
    { @"H",		'H',	4,	NO,	YES	},
    { @"I",		'I',	34,	NO,	YES	},
    { @"J",		'J',	38,	NO,	YES	},
    { @"K",		'K',	40,	NO,	YES	},
    { @"L",		'L',	37,	NO,	YES	},
    { @"M",		'M',	46,	NO,	YES	},
    { @"N",		'N',	45,	NO,	YES	},
    { @"O",		'O',	31,	NO,	YES	},
    { @"P",		'P',	35,	NO,	YES	},
    { @"Q",		'Q',	12,	NO,	YES	},
    { @"R",		'R',	15,	NO,	YES	},
    { @"S",		'S',	1,	NO,	YES	},
    { @"T",		'T',	17,	NO,	YES	},
    { @"U",		'U',	32,	NO,	YES	},
    { @"V",		'V',	9,	NO,	YES	},
    { @"W",		'W',	13,	NO,	YES	},
    { @"X",		'X',	7,	NO,	YES	},
    { @"Y",		'Y',	16,	NO,	YES	},
    { @"Z",		'Z',	6,	NO,	YES	},

    { @"0",		'0',	29,	NO,	YES	},
    { @"1",		'1',	18,	NO,	YES	},
    { @"2",		'2',	19,	NO,	YES	},
    { @"3",		'3',	20,	NO,	YES	},
    { @"4",		'4',	21,	NO,	YES	},
    { @"5",		'5',	23,	NO,	YES	},
    { @"6",		'6',	22,	NO,	YES	},
    { @"7",		'7',	26,	NO,	YES	},
    { @"8",		'8',	28,	NO,	YES	},
    { @"9",		'9',	25,	NO,	YES	},

    { @"^",		'^',	22,	NO,	NO	},
    { @"-",		'-',	27,	NO,	NO	},
    { @"+",		'+',	24,	NO,	NO	},
    { @"[",		'[',	33,	NO,	NO	},
    { @"]",		']',	30,	NO,	NO	},
    { @";",		';',	41,	NO,	NO	},
    { @":",		':',	41,	YES,	NO	},
    { @"\'",		'\'',	39,	NO,	NO	},
    { @"\"",		'\"',	39,	YES,	NO	},
    { @",",		',',	43,	NO,	NO	},
    { @"/",		'/',	44,	NO,	NO	},
    { @"?",		'?',	44,	YES,	NO	},
    { @"\\",		'\\',	42,	NO,	NO	},
    { @"|",		'|',	42,	YES,	NO	},
    
    { @"Space",		0,	49,	NO,	YES	},
    { @"Return",	0,	36,	NO,	YES	},
    { @"Del",		0,	117,	NO,	YES	},
    { @"Tab",		0,	48,	NO,	YES	},
    { @"Esc",		0,	53,	NO,	YES	},
    { @"Delete",	0,	51,	NO,	YES	},

    { @"Up",		0,	126,	NO,	YES	},
    { @"Down",		0,	125,	NO,	YES	},
    { @"Left",		0,	123,	NO,	YES	},
    { @"Right",		0,	124,	NO,	YES	},
    { @"PgUp",		0,	116,	NO,	YES	},
    { @"PgDown",	0,	121,	NO,	YES	},
    { @"Home",		0,	115,	NO,	YES	},
    { @"End",		0,	119,	NO,	YES	},
    
    { @"F1",		0,	122,	NO,	YES	},
    { @"F2",		0,	120,	NO,	YES	},
    { @"F3",		0,	99,	NO,	YES	},
    { @"F4",		0,	118,	NO,	YES	},
    { @"F5",		0,	96,	NO,	YES	},
    { @"F6",		0,	97,	NO,	YES	},
    { @"F7",		0,	98,	NO,	YES	},
    { @"F8",		0,	100,	NO,	YES	},
    { @"F9",		0,	101,	NO,	YES	},
    { @"F10",		0,	109,	NO,	YES	},
    { @"F11",		0,	103,	NO,	YES	},
    { @"F12",		0,	111,	NO,	YES	},
};
int hotkeyDefsCount = sizeof(hotkeyDefs) / sizeof(struct hotkeyDef_t);


@implementation HotkeyEvent

+ (NSArray *)arrayOfKeyNames
{
    int idx;
    NSMutableArray *array;
    
    array = [NSMutableArray arrayWithCapacity:hotkeyDefsCount];
    for (idx = 0; idx < hotkeyDefsCount; idx++) {
        [array addObject:hotkeyDefs[idx].keyName];
    }
    return array;
}

+ (NSArray *)arrayOfLocalizedKeyNames
{
    int idx;
    NSMutableArray *array;
    
    array = [NSMutableArray arrayWithCapacity:hotkeyDefsCount];
    for (idx = 0; idx < hotkeyDefsCount; idx++) {
        [array addObject:NSLocalizedString(hotkeyDefs[idx].keyName, @"")];
    }
    return array;
}

+ (NSString *)keyNameAtIndex:(int)index
{
    return hotkeyDefs[index].keyName;
}

+ (int)indexOfKeyName:(NSString *)name
{
    BOOL found = NO;
    int idx;
    
    for (idx = 0; idx < hotkeyDefsCount; idx++) {
        if ([name isEqualToString:hotkeyDefs[idx].keyName]) {
            found = YES;
            break;
        }
    }
    if (found) return idx;
    NSLog(@"indexOfKeyName - invalid key name given: %@", name);
    return -1;
}

+ (NSArray *)hotkeyArrayWithArray:(NSArray *)anArray
        count:(int)count global:(BOOL)gFlag
{
    int idx;
    NSMutableArray *hotkeys = [NSMutableArray array];
    
    for (idx = 0; idx < count; idx++) {
        id hkev;
        if (idx < [anArray count]) {
            hkev = [[HotkeyEvent alloc]
                    initWithDictionary:[anArray objectAtIndex:idx]];
        } else {
            hkev = [[HotkeyEvent alloc] initWithKeyName:@"M"
                    ctrl:NO alt:NO cmd:YES];
            [hkev setPseudoEventType:
                    (gFlag ? HotkeyDisabled : HotkeyInherit)];
        }
        [hotkeys addObject:[hkev autorelease]];
    }

    return hotkeys;
}

- (HotkeyEvent *)initWithKeyName:(NSString *)name
        ctrl:(BOOL)ctrlFlag alt:(BOOL)altFlag cmd:(BOOL)cmdFlag
{
    [super init];
    [self setKeyName:name];
    [self setCtrl:ctrlFlag];
    [self setAlt:altFlag];
    [self setCmd:cmdFlag];
    [self setPseudoEventType:HotkeyNormalEvent];
    return self;
}

- (void)dealloc
{
    [keyName release];
	[menuLabel release];
	[(id)_menuItemRefCache release];
    [super dealloc];
}

- initWithDictionary:(NSDictionary *)dict
{
    NSString *kn = [dict objectForKey:@"KeyName"];
    if (kn)
        [self setKeyName:kn];
    else
        [self setKeyCode:[[dict objectForKey:@"KeyCode"] intValue]];
    
    [self    setCtrl:[[dict objectForKey:@"Ctrl" ] boolValue]];
    [self     setAlt:[[dict objectForKey:@"Alt"  ] boolValue]];
    [self     setCmd:[[dict objectForKey:@"Cmd"  ] boolValue]];
    [self   setShift:[[dict objectForKey:@"Shift"] boolValue]];
    
    NSNumber *num = [dict objectForKey:@"PseudoEventType"];
    [self setPseudoEventType:num ? [num intValue] : HotkeyNormalEvent];
    
	[self setMenuLabel:[dict objectForKey:@"MenuLabel"]];
	
    return self;
}

- copyWithZone:(NSZone *)zone
{
    id copy = [[[self class] allocWithZone:zone] init];
    [copy setKeyName:keyName];
    [copy setCtrl:ctrl];
    [copy setAlt:alt];
    [copy setCmd:cmd];
    [copy setShift:shift];
    [copy setPseudoEventType:pseudoEventType];
	[copy setMenuItem:[menuLabel copy]];
    return copy;
}

- (NSDictionary *)dictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if ([self keyName])
        [dict setObject:keyName forKey:@"KeyName"];
    else
        [dict setObject:[NSNumber numberWithInt:keyCode] forKey:@"KeyCode"];
    
    [dict setObject:[NSNumber numberWithBool:ctrl]  forKey:@"Ctrl"];
    [dict setObject:[NSNumber numberWithBool:alt]   forKey:@"Alt"];
    [dict setObject:[NSNumber numberWithBool:cmd]   forKey:@"Cmd"];
    [dict setObject:[NSNumber numberWithBool:shift] forKey:@"Shift"];
    
    [dict setObject:[NSNumber numberWithInt:pseudoEventType]
            forKey:@"PseudoEventType"];

	if (menuLabel) [dict setObject:menuLabel forKey:@"MenuLabel"];
	
    return dict;
}

/*
 keyName
   This function retains for backward compatibility.  Use -keyCode or
   -localizedDescription to obtain information.
 */
- (NSString *)keyName
{
    return keyName;
}

- (CGCharCode)charCode
{
    return charCode;
}

- (CGKeyCode)keyCode
{
    return keyCode;
}

- (BOOL)ctrl
{
    return ctrl;
}

- (BOOL)alt
{
    return alt;
}

- (BOOL)cmd
{
    return cmd;
}

- (BOOL)shift
{
    return shift;
}

/*
 setKeyName
   This function retains for backward compatibility.  Use -setKeyCode.
 */
- setKeyName:(NSString *)name
{
    int idx;
    
    [keyName release];
    keyName = [name retain];
    idx = [HotkeyEvent indexOfKeyName:name];
    shift = hotkeyDefs[idx].needShift;
    charCode = hotkeyDefs[idx].charCode;
    keyCode = hotkeyDefs[idx].keyCode;
    canShift = hotkeyDefs[idx].canShift;
    
    return self;
}

- setKeyCode:(CGKeyCode)code
{
    keyCode = code;
    canShift = YES;
    [keyName release];
    keyName = nil;
    return self;
}

- (id)setCtrl:(BOOL)flag
{
    ctrl = flag;
    return self;
}

- (id)setAlt:(BOOL)flag
{
    alt = flag;
    return self;
}

- (id)setCmd:(BOOL)flag
{
    cmd = flag;
    return self;
}

- (id)setShift:(BOOL)flag
{
    if ([self canShift])
        shift = flag;
    return self;
}

- (BOOL)isAlphabet
{
    BOOL flag;
    flag = ([keyName length] == 1 &&
            [[NSCharacterSet uppercaseLetterCharacterSet]
                characterIsMember:[keyName characterAtIndex:0]]);
    return flag;
}

- (BOOL)canShift
{
    return canShift;
}

- (BOOL)_translateKeySymbol:(NSString **)symbolName :(BOOL *)showShift
{
    // Normalize non-special (printable letter) hotkey symbol using
    // Carbon UCKeyTranslate.
    // ex. a -> A
    //     A -> Shift-A
    NSString *kn;
    SInt16 keyScript, keyLayoutID;
    UInt32 deadKeyState = 0;
    Handle uchrHandle, kchrHandle;
    UniCharCount usLen;
    UniChar us[32];
    unsigned int modFlags = 0;
    
    if (shift) modFlags |= shiftKey;
    //if (ctrl)  modFlags |= controlKey;
    //if (alt)   modFlags |= optionKey;
    //if (cmd)   modFlags |= cmdKey;
    modFlags = modFlags >> 8;
    
    keyScript = GetScriptManagerVariable(smKeyScript);
    keyLayoutID = GetScriptVariable(keyScript,smScriptKeys);
    uchrHandle = GetResource('uchr', keyLayoutID);
    if (uchrHandle) {
        UCKeyTranslate((UCKeyboardLayout *)*uchrHandle, keyCode, kUCKeyActionDisplay, modFlags, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, 32, &usLen, us);
        kn = [NSString stringWithCharacters:us length:usLen];
        goto success;
    }

    // uchrHandle is NULL. Try KCHR now...
    kchrHandle = GetResource('KCHR', keyLayoutID);
    if (kchrHandle) {
        UInt32 u2 = KeyTranslate(*kchrHandle, keyCode, &deadKeyState);
        us[0] = (UInt16)u2;     // to be fixed...?
        kn = [NSString stringWithCharacters:us length:(us[0] ? 1 : 0)];
        goto success;
    }
    return NO;
    
success:        
    if (![[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:us[0]]) {
        *showShift = NO;
    }
    *symbolName = [kn uppercaseString];
    return YES;
}


- (NSString *)localizedDescription
{
    NSString *kn = nil;
    BOOL showShift = NO;
    
    if (keyName) {  // for backward compatibility
        kn = keyName;
        showShift = [self shift] && [self canShift];
    } else {
        int i;
        showShift = [self shift];
        for (i = 0; i < hotkeyDefsCount; i++) {
            if (hotkeyDefs[i].keyCode == keyCode) {
                kn = hotkeyDefs[i].keyName;
                break;
            }
        }
        if ([kn length] == 1) {
            NSString *tr;
            if ([self _translateKeySymbol:&tr :&showShift]) kn = tr;
        }
    }
    
    NSString *desc;
    desc = [NSString stringWithFormat:@"%@%@%@%@%@",
            showShift   ? NSLocalizedString(@"Shift", @"") : @"",
            [self ctrl] ? NSLocalizedString(@"Ctrl",  @"") : @"",
            [self alt]  ? NSLocalizedString(@"Alt",   @"") : @"",
            [self cmd]  ? NSLocalizedString(@"Cmd",   @"") : @"",
            NSLocalizedString(kn, @"")];
    return desc;
}

- (HotkeyPseudoEventType)pseudoEventType
{
    return pseudoEventType;
}

- setPseudoEventType:(HotkeyPseudoEventType)eventType
{
    pseudoEventType = eventType;
    return self;
}

- (NSString *)menuLabel
{
	return menuLabel ? menuLabel : @"";
}

- setMenuLabel:(NSString *)newLabel
{
	if (menuLabel) {
		[menuLabel release];
		menuLabel = nil;
	}

	if (newLabel) menuLabel = [newLabel retain];
		
	return self;
}

- (pid_t)pidCache
{
	return _pidCache;
}

- setPidCache:(pid_t)pid
{
	_pidCache = pid;
	return self;
}

- (AXUIElementRef)menuItemRefCache
{
	return (AXUIElementRef)_menuItemRefCache;
}

- setMenuItemRefCache:(AXUIElementRef)menuItemRef
{
	[_menuItemRefCache release];
	_menuItemRefCache = [(id)menuItemRef retain];
	return self;
}

@end
