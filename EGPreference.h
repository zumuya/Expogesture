/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import <Cocoa/Cocoa.h>

@class EGController;
@class EGAppTableView;
@class HotkeyCapture;

@interface EGPreference : NSObject
{
    IBOutlet EGController *appController;
    IBOutlet NSWindow *preferenceWindow;

    IBOutlet NSPopUpButton *rightPseudoPopUp;
    IBOutlet NSTextField *rightLabel;
    IBOutlet HotkeyCapture *rightCapture;
    IBOutlet NSTextField *rightMenuLabel;

    IBOutlet HotkeyCapture *leftCapture;
    IBOutlet NSTextField *leftLabel;
    IBOutlet NSPopUpButton *leftPseudoPopUp;
    IBOutlet NSTextField *leftMenuLabel;

    IBOutlet HotkeyCapture *horizontalCapture;
    IBOutlet NSTextField *horizontalLabel;
    IBOutlet NSPopUpButton *horizontalPseudoPopUp;
    IBOutlet NSTextField *horizontalMenuLabel;

    IBOutlet HotkeyCapture *verticalCapture;
    IBOutlet NSTextField *verticalLabel;
    IBOutlet NSPopUpButton *verticalPseudoPopUp;
    IBOutlet NSTextField *verticalMenuLabel;

    IBOutlet HotkeyCapture *zPathCapture;
    IBOutlet NSTextField *zPathLabel;
    IBOutlet NSPopUpButton *zPathPseudoPopUp;
    IBOutlet NSTextField *zPathMenuLabel;

    IBOutlet HotkeyCapture *nPathCapture;
    IBOutlet NSTextField *nPathLabel;
    IBOutlet NSPopUpButton *nPathPseudoPopUp;
    IBOutlet NSTextField *nPathMenuLabel;
    
    IBOutlet NSTableView *appTable;
    IBOutlet NSButton *removeButton;
    IBOutlet NSButton *usePolling;
    IBOutlet NSSlider *gestureSizeMin;
    IBOutlet NSTextField *gestureSizeMinLabel;
    IBOutlet NSButton *bringAllCheck;
    IBOutlet NSButton *createNewCheck;
    IBOutlet NSImageView *notifWinPreview;
    IBOutlet NSMatrix *notifWinPosMatrix;
	
    NSArray *pseudoEventPopUpArray;
    NSArray *labelArray;
    NSArray *captureArray;
	NSArray *menuLabelArray;
}

- (void)awakeFromNib;
- (void)windowWillClose:(NSNotification *)aNotification;

- (IBAction)openPreferenceWindow:(id)sender;
- (IBAction)pseudoEventPopUpSelected:sender;
- (IBAction)menuLabelChanged:sender;
- (IBAction)addApplication:(id)sender;
- (IBAction)removeApplication:(id)sender;
- (IBAction)tableSelected:(id)sender;
- (IBAction)gestureSizeChanged:sender;
- (IBAction)bringAllCheckSelected:sender;
- (IBAction)createNewCheckSelected:sender;
- (IBAction)notifWinPosChanged:sender;

- (int)numberOfRowsInTableView:(NSTableView *)tableView;
- tableView:(NSTableView *)tableView
        objectValueForTableColumn:(NSTableColumn *)tableColumn
        row:(int)row;
- (void)appTableView:(EGAppTableView *)view
        addApplicationPath:(NSString *)path;

@end
