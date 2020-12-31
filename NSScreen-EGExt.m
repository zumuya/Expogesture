/*
    Copyright (C) 2003-2004 NAKAHASHI Ichiro

    This program is distributed under the GNU Public License.
    This program comes with NO WARRANTY.
*/

#import "NSScreen-EGExt.h"

@implementation NSScreen (EGExtention)

+ (NSScreen *)screenUnderMouse
{
    NSArray *sary = [self screens];
    int i;
    for (i = 0; i < [sary count]; i++) {
        NSScreen *s = [sary objectAtIndex:i];
        if (NSMouseInRect([NSEvent mouseLocation], [s frame], NO)) return s;
    }
    return nil;
}

@end
