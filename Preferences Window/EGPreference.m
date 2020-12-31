/*
	Copyright (C) 2003-2004 NAKAHASHI Ichiro

	This program is distributed under the GNU Public License.
	This program comes with NO WARRANTY.
*/

#import "EGCommon.h"
#import "EGPreference.h"
#import "EGController.h"
#import "HotkeyEvent.h"
#import "HotkeyCapture.h"

@implementation EGPreference

- (NSString *)_appNameAtIndex:(int)index
{
	NSMutableArray *appList =
			[[[appController eventKeyDefs] allKeys] mutableCopy];
	[appList removeObject:@"_Global"];
	[appList insertObject:@"_Global" atIndex:0];

	return [appList objectAtIndex:index];
}

- (void)_setupEventPrefsForApp:(NSString *)appName
{
	NSArray *keyDefs = [[appController eventKeyDefs] objectForKey:appName];
	int eventId, eventCount;
	
	eventCount = [keyDefs count];
	for (eventId = 0; eventId < eventCount; eventId++) {
		HotkeyEvent *hotkey = [keyDefs objectAtIndex:eventId];
		NSPopUpButton *pseudoPop =
				[pseudoEventPopUpArray objectAtIndex:eventId];
		NSTextField *label = [labelArray objectAtIndex:eventId];
		HotkeyCapture *capture = [captureArray objectAtIndex:eventId];
		NSTextField *menuLabel = [menuLabelArray objectAtIndex:eventId];

		HotkeyPseudoEventType et = [hotkey pseudoEventType];
		
		NSMenu *menu = [[NSMenu alloc] initWithTitle:@"PopUp"];
		if (![appName isEqualToString:EGGlobalAppName]) {
			[[menu addItemWithTitle:
					NSLocalizedString(@"Use Global Setting", @"")
					action:nil keyEquivalent:@""] setTag:HotkeyInherit];
		}
		[[menu addItemWithTitle:NSLocalizedString(@"Disabled", @"")
				action:nil keyEquivalent:@""] setTag:HotkeyDisabled];
		[[menu addItemWithTitle:NSLocalizedString(@"Send Key Event", @"")
				action:nil keyEquivalent:@""] setTag:HotkeyNormalEvent];
		[[menu addItemWithTitle:NSLocalizedString(@"Pick A Menu Item", @"")
				action:nil keyEquivalent:@""] setTag:HotkeyMenuItem];
		[pseudoPop setMenu:menu];
		[pseudoPop selectItemAtIndex:[pseudoPop indexOfItemWithTag:et]];

		switch (et) {
		case HotkeyNormalEvent:
			[label setStringValue:NSLocalizedString(@"Key Sent", @"")];
			[capture setHidden:NO];
			[menuLabel setHidden:YES];
			[capture setHotkey:hotkey];
			break;
		case HotkeyMenuItem:
			[label setStringValue:NSLocalizedString(@"Menu Label", @"")];
			[capture setHidden:YES];
			[menuLabel setHidden:NO];
			[menuLabel setStringValue:[hotkey menuLabel]];
			break;
		default:
			[label setStringValue:@""];
			[capture setHidden:YES];
			[menuLabel setHidden:YES];
		}
	}
}

- (void)awakeFromNib
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	pseudoEventPopUpArray = [[NSArray alloc] initWithObjects:
			rightPseudoPopUp, leftPseudoPopUp,
			horizontalPseudoPopUp, verticalPseudoPopUp,
			zPathPseudoPopUp, nPathPseudoPopUp,
			nil];

	labelArray = [[NSArray alloc] initWithObjects:
			rightLabel, leftLabel,
			horizontalLabel, verticalLabel,
			zPathLabel, nPathLabel,
			nil];
	
	captureArray = [[NSArray alloc] initWithObjects:
			rightCapture, leftCapture,
			horizontalCapture, verticalCapture,
			zPathCapture, nPathCapture,
			nil];
	
	menuLabelArray = [[NSArray alloc] initWithObjects:
			rightMenuLabel, leftMenuLabel,
			horizontalMenuLabel, verticalMenuLabel,
			zPathMenuLabel, nPathMenuLabel,
			nil];
	
	[gestureSizeMin setIntValue:[appController gestureSizeMin]];
	[gestureSizeMinLabel setIntValue:[appController gestureSizeMin]];
	[bringAllCheck setState:
			[defaults boolForKey:@"BringsAllWindowsToFront"]];
	[createNewCheck setState:
			[defaults boolForKey:@"CreatesNewDocumentIfNone"]];

	[appTable registerForDraggedTypes:
			[NSArray arrayWithObject:NSPasteboardTypeFileURL]];

	[self _setupEventPrefsForApp:@"_Global"];
	[self notifWinPosChanged:nil];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	NSDictionary *keyDefs = [appController eventKeyDefs];
	NSMutableDictionary *keyDefsDict = [NSMutableDictionary dictionary];
	NSEnumerator *anEnum;
	NSString *key;
	
	anEnum = [[keyDefs allKeys] objectEnumerator];
	while (key = [anEnum nextObject]) {
		int idx;
		NSArray *hotkeys = [keyDefs objectForKey:key];
		NSMutableArray *appArray = [NSMutableArray array];
		for (idx = 0; idx < [hotkeys count]; idx++) {
			[appArray addObject:[[hotkeys objectAtIndex:idx] dictionary]];
		}
		[keyDefsDict setObject:appArray forKey:key];
	}
	
	[defaults setObject:keyDefsDict forKey:@"EventKeyDefs"];
	
	[defaults setInteger:[gestureSizeMin intValue]
			forKey:@"GestureSizeMin"];
	[defaults setBool:[bringAllCheck state]
			forKey:@"BringsAllWindowsToFront"];
	[defaults setBool:[createNewCheck state]
			forKey:@"CreatesNewDocumentIfNone"];
	
	[defaults synchronize];
	
	if (![defaults boolForKey:@"ShowStatusBarMenu"])
		[appController hideStatusBarMenu];
}

- (IBAction)openPreferenceWindow:(id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	// Make Expogesture itself a front application
	[NSApp activateIgnoringOtherApps:YES];

	// Show Status Menu Bar
	if (![defaults boolForKey:@"ShowStatusBarMenu"])
		[appController showStatusBarMenu];

	// Show Preference panel
	[preferenceWindow makeKeyAndOrderFront:self];
}


- (IBAction)pseudoEventPopUpSelected:sender
{
	int tableRow = [appTable selectedRow];
	NSString *appName = [self _appNameAtIndex:tableRow];
	NSArray *keyDefs =
			[[appController eventKeyDefs] objectForKey:appName];

	int eventId = [sender tag];
	HotkeyEvent *hotkey = [keyDefs objectAtIndex:eventId];

	HotkeyPseudoEventType et = [[sender selectedItem] tag];
	[hotkey setPseudoEventType:et];
	[self _setupEventPrefsForApp:appName];
}


- (IBAction)menuLabelChanged:sender
{
	int tableRow = [appTable selectedRow];
	NSString *appName = [self _appNameAtIndex:tableRow];
	NSArray *keyDefs =
			[[appController eventKeyDefs] objectForKey:appName];

	int eventId = [sender tag];
	HotkeyEvent *hotkey = [keyDefs objectAtIndex:eventId];

	[hotkey setMenuLabel:[sender stringValue]];
}


- (void)_addEventDefForAppPath:(NSString *)appPath
{
	NSUserDefaults *def = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *hotkeyDefRoot;
	NSArray *globalHotkeyDef, *newHotkeyDef;
	
	hotkeyDefRoot = [appController eventKeyDefs];
	globalHotkeyDef = [hotkeyDefRoot objectForKey:@"_Global"];
	newHotkeyDef = [HotkeyEvent hotkeyArrayWithArray:
			[def objectForKey:@"DefaultHotkeyDefForAnApplication"]
				count:[globalHotkeyDef count]
				global:NO];
	[hotkeyDefRoot setObject:newHotkeyDef forKey:appPath];
}

- (void)_didEndOpenSheet:(NSOpenPanel *)panel
		returnCode:(int)ret contextInfo:(void *)context
{
	
}

- (IBAction)addApplication: (id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel]; {
		[panel setAllowsMultipleSelection:YES];
		[panel setCanChooseFiles:YES];
		[panel setDirectoryURL: [NSURL fileURLWithPath: @"/Applications"]];
		[panel setAllowedFileTypes: @[@"app"]];
	}
	[panel beginSheetModalForWindow: [sender window] completionHandler:^(NSInteger result) {
		if (result == NSModalResponseOK) {
			for (NSURL* url in panel.URLs) {
				[self _addEventDefForAppPath: url.absoluteString];
			}
			[appTable reloadData];
			[self tableSelected:appTable];
		}
	}];
}

- (IBAction)removeApplication:(id)sender
{
	int row;
	NSString *appName;

	row  = [appTable selectedRow];
	NSArray *localized = [[NSFileManager defaultManager]
			componentsToDisplayForPath:[self _appNameAtIndex:row]];
	appName = [localized lastObject];

	NSAlert* alert = [[NSAlert alloc] init]; {
		[alert setMessageText: NSLocalizedString(@"Remove Application", @"")];
		[alert setInformativeText: [NSString stringWithFormat: NSLocalizedString(@"Remove %@?", @""), appName]];
		[alert addButtonWithTitle: NSLocalizedString(@"Yes", @"")];
		[alert addButtonWithTitle: NSLocalizedString(@"Cancel", @"")];
	}
	[alert beginSheetModalForWindow: preferenceWindow completionHandler: ^(NSModalResponse returnCode) {
		if (returnCode == NSAlertSecondButtonReturn) {
			int row;//, numOfRow;
			NSString *appName;
			NSMutableDictionary *hotkeyDefRoot;
			
			row  = [appTable selectedRow];
			appName = [self _appNameAtIndex:row];
			hotkeyDefRoot = [appController eventKeyDefs];
			[hotkeyDefRoot removeObjectForKey:appName];
			
			[appTable reloadData];
			[self tableSelected:appTable];
		}
	}];
}

- (IBAction)tableSelected:(id)sender
{
	int row;
	NSString *appName;
	
	row  = [sender selectedRow];
	if (row < 0) return;
	
	appName = [self _appNameAtIndex:row];
	if ([appName isEqualToString:@"_Global"])
		[removeButton setEnabled:NO];
	else
		[removeButton setEnabled:YES];
		
	[self _setupEventPrefsForApp:appName];
}

- (IBAction)gestureSizeChanged:sender
{
	[appController setGestureSizeMin:[sender intValue]];
	[gestureSizeMinLabel setIntValue:[sender intValue]];
}

- (IBAction)bringAllCheckSelected:sender
{

}

- (IBAction)createNewCheckSelected:sender
{

}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [[appController eventKeyDefs] count];
}

- tableView:(NSTableView *)tableView
		objectValueForTableColumn:(NSTableColumn *)tableColumn
		row:(int)row
{
	NSString *appName;
	enum {AppName, FullPath} columnId;
	
	if ([[tableColumn identifier] isEqualToString:@"AppName"])
		columnId = AppName;
	else
		columnId = FullPath;
	
	appName = [self _appNameAtIndex:row];
	if ([appName isEqualToString:@"_Global"]) {
		if (columnId == AppName)
			appName = NSLocalizedString(@"(Global Definitions)", @"");
		else
			appName = @"";
	} else {
		NSArray *localized = [[NSFileManager defaultManager]
									componentsToDisplayForPath: appName];
		if (columnId == AppName)
			appName = [localized lastObject];
		else
			appName = [localized componentsJoinedByString:@":"];
	}
	return appName;
}

- (void)appTableView:(EGAppTableView *)view
		addApplicationPath:(NSString *)path
{
	[self _addEventDefForAppPath:path];
	[appTable reloadData];
}

- (IBAction)notifWinPosChanged:sender
{
	NSString *pfName = [NSString stringWithFormat:@"NotifPos%li",
			[[notifWinPosMatrix selectedCell] tag] ?: 0];
	NSImage *previewImg = [NSImage imageNamed:pfName];
	[notifWinPreview setImage:previewImg];
}

@end
