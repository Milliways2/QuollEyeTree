//
//  MyWindowController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 4/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
// Quartz framework provides the QLPreviewPanel public API
#import <Quartz/Quartz.h>
#import "TreeViewControllerDelegate.h"
#import "SidebarViewControllerDelegate.h"
#import "SFTabView.h"
#import "DeletedItemsDelegate.h"
@class TreeViewController;
@class SidebarViewController;
@class DirectoryItem;

@interface MyWindowController : NSWindowController <NSToolbarDelegate, QLPreviewPanelDataSource, QLPreviewPanelDelegate, TreeViewControllerDelegate, SidebarViewControllerDelegate, SFTabViewDelegate, DeletedItemsDelegate> {
	IBOutlet NSButton *showTagged;
	IBOutlet NSMenu *fileMenu;
	IBOutlet NSMenu *dirMenu;
	IBOutlet NSMenu *goMenu;
	IBOutlet NSSearchField *filterString;
    IBOutlet NSProgressIndicator *refresh;
	TreeViewController *currentTvc;
	TreeViewController *previousTvc;
    SidebarViewController *sidebarController;
    QLPreviewPanel *previewPanel;
    NSArray *panelData;
	NSNumber *lastEventId;
    FSEventStreamRef stream;
	NSMapTable *viewMap;    // relationsship between View and Tab
    NSInteger pauseCount;
//	IBOutlet SFTabView *__unsafe_unretained tabViewBar;
//    IBOutlet NSDrawer *__unsafe_unretained sidebarDrawer;
}

@property (assign) IBOutlet NSView *viewContainer;
@property (readonly) TreeViewController *currentTvc;
@property (unsafe_unretained, readonly) IBOutlet SFTabView *tabViewBar;
@property (unsafe_unretained, readonly) IBOutlet NSDrawer *sidebarDrawer;

- (NSArray *)tvcInTabs;
- (NSInteger)currentTab;
- (TreeViewController *)tvcAtIndex:(NSInteger)index;

// Toolbar Actions
- (IBAction)segControlClicked:(id)sender;
- (IBAction)togglePreviewPanel:(id)sender;
- (IBAction)toggleShowTagged:(id)sender;
//- (IBAction)openSidebar:(id)sender;
//- (IBAction)closeSidebar:(id)sender;
- (IBAction)toggleSidebar:(id)sender;
- (IBAction)privateTest:(id)sender;
- (IBAction)toggleMark:(id)sender;
- (IBAction)currentFileFilter:(id)sender;
	
// Menu Actions (called in AppDelegate)
- (IBAction)addNewTab:(id)sender;
- (IBAction)removeThisTab: (id)sender;
- (IBAction)addNewTabAt:(id)sender;
- (IBAction)toggleView:(id)sender;

- (IBAction)gotoDir:(id)sender;
- (IBAction)goBack:(id)sender;
@end
