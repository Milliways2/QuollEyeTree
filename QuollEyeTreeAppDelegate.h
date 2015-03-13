//
// QuollEyeTreeAppDelegate.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 10/06/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MyWindowController;
@class PreferencesController;

@interface QuollEyeTreeAppDelegate : NSObject <NSApplicationDelegate> {
	IBOutlet MyWindowController *myWindowController;
    PreferencesController *preferencesController;
}
@property (readonly) MyWindowController *myWindowController;

- (IBAction)openPreferences:(id)sender;
- (IBAction)openReadMe:(id)sender;
- (IBAction)sendMailCocoa:(id)sender;
- (IBAction)openDocumentation:(id)sender;
- (IBAction)openHomePage:(id)sender;
// MyWindowController Menu Actions
- (IBAction)addNewTab:(id)sender;
- (IBAction)removeThisTab: (id)sender;
- (IBAction)toggleToolbarShown:(id)sender;
- (IBAction)addNewTabAt:(id)sender;
- (IBAction)toggleSidebar:(id)sender;
- (IBAction)toggleView:(id)sender;

@end
