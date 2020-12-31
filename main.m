/*
	Copyright (C) 2003-2004 NAKAHASHI Ichiro

	This program is distributed under the GNU Public License.
	This program comes with NO WARRANTY.
*/

#include <limits.h>
#include <unistd.h>
#include <sys/stat.h>

#import <Cocoa/Cocoa.h>

void migratePlistSettings()
{
	struct stat st;
	char pref_dir[PATH_MAX + 1];
	char old_plist[PATH_MAX + 1];
	char new_plist[PATH_MAX + 1];
	pref_dir[PATH_MAX] = old_plist[PATH_MAX] = new_plist[PATH_MAX] = 0;
	
	snprintf(pref_dir, PATH_MAX, "%s/Library/Preferences/", getenv("HOME"));
	snprintf(old_plist, PATH_MAX, "%sforbidden_methods.Expogesture.plist", pref_dir);
	snprintf(new_plist, PATH_MAX, "%sorg.nnip.Expogesture.plist", pref_dir);

	if (stat(old_plist, &st) < 0) return;	   // old one does not exist
	if (stat(new_plist, &st) == 0) return;	  // new one already exists
	
	/* Ok, now ready to migrate settings */
	link(old_plist, new_plist);
}


int main(int argc, const char *argv[])
{
	migratePlistSettings();
	return NSApplicationMain(argc, argv);
}
