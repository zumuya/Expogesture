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
	{@"A",		'A',	0,	NO,	YES, nil},
	{@"B",		'B',	11,	NO,	YES, nil},
	{@"C",		'C',	8,	NO,	YES, nil},
	{@"D",		'D',	2,	NO,	YES, nil},
	{@"E",		'E',	14,	NO,	YES, nil},
	{@"F",		'F',	3,	NO,	YES, nil},
	{@"G",		'G',	5,	NO,	YES, nil},
	{@"H",		'H',	4,	NO,	YES, nil},
	{@"I",		'I',	34,	NO,	YES, nil},
	{@"J",		'J',	38,	NO,	YES, nil},
	{@"K",		'K',	40,	NO,	YES, nil},
	{@"L",		'L',	37,	NO,	YES, nil},
	{@"M",		'M',	46,	NO,	YES, nil},
	{@"N",		'N',	45,	NO,	YES, nil},
	{@"O",		'O',	31,	NO,	YES, nil},
	{@"P",		'P',	35,	NO,	YES, nil},
	{@"Q",		'Q',	12,	NO,	YES, nil},
	{@"R",		'R',	15,	NO,	YES, nil},
	{@"S",		'S',	1,	NO,	YES, nil},
	{@"T",		'T',	17,	NO,	YES, nil},
	{@"U",		'U',	32,	NO,	YES, nil},
	{@"V",		'V',	9,	NO,	YES, nil},
	{@"W",		'W',	13,	NO,	YES, nil},
	{@"X",		'X',	7,	NO,	YES, nil},
	{@"Y",		'Y',	16,	NO,	YES, nil},
	{@"Z",		'Z',	6,	NO,	YES, nil},

	{@"0",		'0',	29,	NO,	YES, nil},
	{@"1",		'1',	18,	NO,	YES, nil},
	{@"2",		'2',	19,	NO,	YES, nil},
	{@"3",		'3',	20,	NO,	YES, nil},
	{@"4",		'4',	21,	NO,	YES, nil},
	{@"5",		'5',	23,	NO,	YES, nil},
	{@"6",		'6',	22,	NO,	YES, nil},
	{@"7",		'7',	26,	NO,	YES, nil},
	{@"8",		'8',	28,	NO,	YES, nil},
	{@"9",		'9',	25,	NO,	YES, nil},

	{@"^",		'^',	22,	NO,	NO, nil},
	{@"-",		'-',	27,	NO,	NO, nil},
	{@"+",		'+',	24,	NO,	NO, nil},
	{@"[",		'[',	33,	NO,	NO, nil},
	{@"]",		']',	30,	NO,	NO, nil},
	{@";",		';',	41,	NO,	NO, nil},
	{@":",		':',	41,	YES,	NO, nil},
	{@"\'",		'\'',	39,	NO,	NO, nil},
	{@"\"",		'\"',	39,	YES,	NO, nil},
	{@",",		',',	43,	NO,	NO, nil},
	{@"/",		'/',	44,	NO,	NO, nil},
	{@"?",		'?',	44,	YES,	NO, nil},
	{@"\\",		'\\',	42,	NO,	NO, nil},
	{@"|",		'|',	42,	YES,	NO, nil},
	
	{@"Space",		0,	49,	NO,	YES, nil},
	{@"Return",	0,	36,	NO,	YES, nil},
	{@"Del",		0,	117,	NO,	YES, nil},
	{@"Tab",		0,	48,	NO,	YES, nil},
	{@"Esc",		0,	53,	NO,	YES, nil},
	{@"Delete",	0,	51,	NO,	YES, nil},

	{@"Up",		0,	126,	NO,	YES, nil},
	{@"Down",		0,	125,	NO,	YES, nil},
	{@"Left",		0,	123,	NO,	YES, nil},
	{@"Right",		0,	124,	NO,	YES, nil},
	{@"PgUp",		0,	116,	NO,	YES, nil},
	{@"PgDown",	0,	121,	NO,	YES, nil},
	{@"Home",		0,	115,	NO,	YES, nil},
	{@"End",		0,	119,	NO,	YES, nil},
	
	{@"F1",		0,	122,	NO,	YES, nil},
	{@"F2",		0,	120,	NO,	YES, nil},
	{@"F3",		0,	99,	NO,	YES, nil},
	{@"F4",		0,	118,	NO,	YES, nil},
	{@"F5",		0,	96,	NO,	YES, nil},
	{@"F6",		0,	97,	NO,	YES, nil},
	{@"F7",		0,	98,	NO,	YES, nil},
	{@"F8",		0,	100,	NO,	YES, nil},
	{@"F9",		0,	101,	NO,	YES, nil},
	{@"F10",		0,	109,	NO,	YES, nil},
	{@"F11",		0,	103,	NO,	YES, nil},
	{@"F12",		0,	111,	NO,	YES, nil},
	
	{@"Mission Control", 0, 160, NO, YES, @"􀇴"},
	{@"Launchpad", 0, 130, NO, YES, @"􀇵"},
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

+ (int)indexOfKeyCode:(CGKeyCode)keyCode
{
	BOOL found = NO;
	int idx;
	
	for (idx = 0; idx < hotkeyDefsCount; idx++) {
		if (keyCode == hotkeyDefs[idx].keyCode) {
			found = YES;
			break;
		}
	}
	if (found) return idx;
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
			hkev = [[HotkeyEvent alloc] initWithKeyCode:0
					ctrl:NO alt:NO cmd:YES];
			[hkev setPseudoEventType:
					(gFlag ? HotkeyDisabled : HotkeyInherit)];
		}
		[hotkeys addObject:hkev];
	}

	return hotkeys;
}

- (HotkeyEvent *)initWithKeyCode:(CGKeyCode)keyCode
		ctrl:(BOOL)ctrlFlag alt:(BOOL)altFlag cmd:(BOOL)cmdFlag
{
	self = [super init];
	[self setKeyCode:keyCode];
	[self setCtrl:ctrlFlag];
	[self setAlt:altFlag];
	[self setCmd:cmdFlag];
	[self setPseudoEventType:HotkeyNormalEvent];
	return self;
}

- initWithDictionary:(NSDictionary *)dict
{
	CGKeyCode keyCode = [[dict objectForKey:@"KeyCode"] intValue];
	BOOL ctrl = [[dict objectForKey:@"Ctrl" ] boolValue];
	BOOL alt = [[dict objectForKey:@"Alt"  ] boolValue];
	BOOL cmd = [[dict objectForKey:@"Cmd"  ] boolValue];
	BOOL shift = [[dict objectForKey:@"Shift"] boolValue];
	self = [self initWithKeyCode: keyCode ctrl: ctrl alt: alt cmd: cmd];
	[self setShift: shift];
	
	NSNumber *num = [dict objectForKey:@"PseudoEventType"];
	[self setPseudoEventType:num ? [num intValue] : HotkeyNormalEvent];
	
	[self setMenuLabel:[dict objectForKey:@"MenuLabel"]];
	
	return self;
}

- copyWithZone:(NSZone *)zone
{
	id copy = [[[self class] allocWithZone:zone] init];
	[copy setKeyCode:keyCode];
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

- setKeyCode:(CGKeyCode)code
{
	keyCode = code;
	
	int idx = [HotkeyEvent indexOfKeyCode: keyCode];
	if (idx == -1) {
		keyName = nil;
		canShift = YES;
	} else {
		keyName = hotkeyDefs[idx].keyName;
		canShift = hotkeyDefs[idx].canShift;
	}
	
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
	//	 A -> Shift-A
	
	//TODO: Implement this!!!
	return YES;
	
	/*NSString *kn;
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
		us[0] = (UInt16)u2;	 // to be fixed...?
		kn = [NSString stringWithCharacters:us length:(us[0] ? 1 : 0)];
		goto success;
	}
	return NO;
	
success:		
	if (![[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:us[0]]) {
		*showShift = NO;
	}
	*symbolName = [kn uppercaseString];
	return YES;*/
}

-(NSString*)symbolName API_AVAILABLE(macosx(11.0))
{
	NSInteger index = [HotkeyEvent indexOfKeyCode: self.keyCode];
	return ((index == -1) ? nil : hotkeyDefs[index].sfSymbol);
}

- (NSString *)localizedDescription
{
	NSString *kn = nil;
	BOOL showShift = NO;
	
	NSInteger index = [HotkeyEvent indexOfKeyCode: keyCode];
	if (index != -1) {
		if (@available(macOS 11, *)) {
			kn = (hotkeyDefs[index].sfSymbol ?: hotkeyDefs[index].keyName);
		} else {
			kn = hotkeyDefs[index].keyName;
		}
	}
	
	showShift = [self shift];
	if ([kn length] == 1) {
		NSString *tr = kn;
		if ([self _translateKeySymbol:&tr :&showShift]) kn = tr;
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
		menuLabel = nil;
	}

	if (newLabel) menuLabel = newLabel.copy;
		
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
	return (__bridge AXUIElementRef)_menuItemRefCache;
}

- setMenuItemRefCache:(AXUIElementRef)menuItemRef
{
	_menuItemRefCache = (__bridge id)menuItemRef;
	return self;
}

@end
