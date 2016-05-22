// QuollEyeTreeAppDelegate.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 10/06/11.
//  Copyright 2011 Ian Binnie. All rights reserved.

#import "QuollEyeTreeAppDelegate.h"
#import "volume.h"
#import "DirectoryItem.h"
#import "MyWindowController.h"
#import "TreeViewController.h"
#import "PreferencesController.h"
#import "MyWindowController+Refresh.h"
#import "IBDateFormatter.h"
#import "ArrayCountTransformer.h"
#import "ArraySumTransformer.h"

@implementation QuollEyeTreeAppDelegate
@synthesize myWindowController;

+(void)initialize {
	NSString *defaultDirectory = NSHomeDirectory();
	NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
							  COLUMNID_DATE, PREF_SORT_FIELD,
							  @"NO", PREF_SORT_DIRECTION,
							  @"YES", PREF_DIRECTORY_ICON,
							  @"YES", PREF_FILE_ICON,
							  @"NO", PREF_HIDDEN_FILES,
							  @"YES", PREF_AUTOMATIC_REFRESH,
							  defaultDirectory, PREF_DEFAULT_DIR,
							  defaultDirectory, PREF_REFRESH_DIR,
							  @"0.5", PREF_SPLIT_PERCENTAGE,
							  @"0.5", PREF_SPLIT_PERCENTAGE_H,
							  @"NO", PREF_SPLIT_ORIENTATION,
							  [NSNumber numberWithInteger:ISO8601ShortStyle], PREF_DATE_FORMAT,
							  @"NO", PREF_DATE_RELATIVE,
                              @"NO", PREF_DATE_SHOW_CREATE,
							  DEFAULT_COMPARE_COMMAND, PREF_COMPARE_COMMAND,
							  DEFAULT_EDIT_COMMAND, PREF_EDIT_COMMAND,
							  @"%1", PREF_BATCH_CMD,
							  nil];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

    initializeVolumes();

    // create and register ArrayCountTransformer value transformer
    ArrayCountTransformer *countTransformer = [[ArrayCountTransformer alloc] init];
    [NSValueTransformer setValueTransformer:countTransformer forName:@"ArrayCountTransformer"];
    ArraySumTransformer *sumTransformer = [[ArraySumTransformer alloc] init];
    [NSValueTransformer setValueTransformer:sumTransformer forName:@"ArraySumTransformer"];
}

#pragma mark NSApplicationDelegate Protocol
//	NSApplication delegate method placed here so program quits after we close the window.
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender {
	return YES;
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)app {
    return NSTerminateNow;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// load the app's main window for display
	myWindowController = [[MyWindowController alloc] initWithWindowNibName:@"MainWindow"];
#ifdef BETA_HEADER
	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	NSString *body = [NSString stringWithFormat:@"%@ %@ (build %@)",
					  [bundleInfo objectForKey:@"CFBundleExecutable"],
					  [bundleInfo objectForKey:@"CFBundleShortVersionString"],
					  [bundleInfo objectForKey:@"CFBundleVersion"]];
	[myWindowController.window setTitle:body];
#endif
}
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(toggleToolbarShown:)) {
        if (myWindowController.window.toolbar.isVisible) {
            [menuItem setTitle:@"Hide Toolbar"];
        } else {
            [menuItem setTitle:@"Show Toolbar"];
        }
        return YES;
    }
    if (action == @selector(toggleSidebar:)) {
        if ([[myWindowController sidebarDrawer] state] == NSDrawerOpenState) {
            [menuItem setTitle:@"Hide Sidebar"];
        } else {
            [menuItem setTitle:@"Show Sidebar"];
        }
        return YES;
    }
	if (action == @selector(removeTab:)) {
        if ([[myWindowController tabViewBar] numberOfTabs] > 1) {
			return YES;
        } else {
			return NO;
        }
    }
	if (action == @selector(addNewTabAt:)) {
		[menuItem setTitle:[NSString stringWithFormat:@"New Tab \"%@\"", [[[myWindowController currentTvc] selectedDir] relativePath]]];
    }
    return YES;
}

#pragma mark Button Actions
- (IBAction)openReadMe:(id)sender {
	NSString *fullReadMePath = [[NSBundle mainBundle] pathForResource:@"ReadMe" ofType:@"txt"];
	[[NSWorkspace sharedWorkspace] openFile:fullReadMePath];
}

- (IBAction)openPreferences:(id)sender {
    if (preferencesController == nil)
    preferencesController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
	[preferencesController showWindow:self];
}

// Create a mail message in the user's preferred mail client by opening a mailto URL.
- (IBAction)sendMailCocoa:(id)sender {
	NSString *version = [[NSProcessInfo processInfo] operatingSystemVersionString];
	NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
	NSString *subject = [NSString stringWithFormat:@"?subject=%@%%20Support%%20Request",
						 [bundleInfo objectForKey:@"CFBundleExecutable"]];
	NSString *body = [NSString stringWithFormat:@"&body=%@ %@ (build %@) %@",
					  [bundleInfo objectForKey:@"CFBundleExecutable"],
					  [bundleInfo objectForKey:@"CFBundleShortVersionString"],
					  [bundleInfo objectForKey:@"CFBundleVersion"],
					  version];
	
	NSString *mail = [NSString stringWithFormat:@"mailto:support@binnie.id.au%@%@", subject, [body stringByReplacingOccurrencesOfString:@" " withString:@"%20" ]];
    NSURL *url = [NSURL URLWithString:mail];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)openDocumentation:(id)sender {
	NSURL *docFile = [[NSBundle mainBundle] URLForResource:@"QuollEyeTree" withExtension:@"pdf"];
	LSOpenCFURLRef((__bridge CFURLRef)docFile, nil);
}
- (IBAction)openHomePage:(id)sender {
	NSURL *url = [NSURL URLWithString:@"http://binnie.id.au/QuollEyeTree.html"];
	[[NSWorkspace sharedWorkspace] openURL:url];
}
#pragma mark  MyWindowController Menu Actions
- (IBAction)addNewTab:(id)sender {
	[myWindowController addNewTab:sender];
}
- (IBAction)removeThisTab: (id)sender {
	[myWindowController removeThisTab:sender];
}
- (IBAction)toggleToolbarShown:(id)sender {
	[myWindowController.window.toolbar setVisible:!myWindowController.window.toolbar.isVisible];
}
- (IBAction)addNewTabAt:(id)sender {
	[myWindowController addNewTabAt:sender];
}
- (IBAction)toggleSidebar:(id)sender {
	[myWindowController toggleSidebar:sender];
}
- (IBAction)toggleView:(id)sender {
	[myWindowController toggleView:sender];
}

@end
