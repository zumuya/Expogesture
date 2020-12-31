/*
	Copyright (C) 2003-2004 NAKAHASHI Ichiro, (C) 2020-2021 zumuya

	This program is distributed under the GNU Public License.
	This program comes with NO WARRANTY.
*/

#import <Cocoa/Cocoa.h>

@interface NotificationWindowController: NSWindowController
{
	NSTimer* closingTimer;
	
	NSTextField* textLabel;
}

+(instancetype)sharedController;

-(void)showWithText:(NSString *)text;
-(void)dismissWithFade;

@end
