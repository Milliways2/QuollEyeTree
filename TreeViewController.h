//
//  TreeViewController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 13/06/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeViewControllerDelegate.h"
#import "MyOutlineView.h"

//@class MyOutlineView;
@class DirectoryItem;
@class CopyPanelController;
@class RenamePanelController;
@class TextViewerController;
@class OpenWith;

@interface TreeViewController : NSViewController <NSMenuDelegate, MyOutlineViewDelegate> {
	DirectoryItem *__unsafe_unretained dataRoot;
	CGFloat previousSplitViewHeight;
	NSString *savedSearchString;
	NSPredicate *fileFilterPredicate;
	NSPredicate *tagPredicate;
    NSPredicate *notEmptyPredicate;
	BOOL showOnlyTagged;
	BOOL inFileView;
	BOOL inBranch;
	BOOL quickLook;
	BOOL cancelAll;
	CopyPanelController *copyPanel;
	RenamePanelController *renamePanel;
    TextViewerController *textViewer;
    OpenWith *openWithClass;    // need to hang on to class for ARC
    NSArray *filesToView;
    NSUInteger currentFileToView;
    NSInteger spinCount;
    NSOperationQueue *queue;
}

@property (assign) IBOutlet NSSplitView *split;
@property (assign) IBOutlet NSScrollView *splitViewTop;
@property (assign) IBOutlet NSArrayController *arrayController;
@property (assign) IBOutlet MyOutlineView *dirTree;
@property (assign) IBOutlet NSTableView *fileList;
@property (assign) IBOutlet NSPathControl *currentPath;
@property (assign) IBOutlet NSProgressIndicator *progress;

@property (assign) id delegate;
@property (assign) NSMutableArray *filesInDir;
@property (assign) DirectoryItem *selectedDir;    // item to display
@property (copy) NSURL *currDir;    // binding to NSPathControl *currentPath

- (NSString *)rootDirName;
- (void)activateTreeView;
- (void)reloadData;
- (void)setTreeRootNode:(DirectoryItem *)node;
- (DirectoryItem *)treeRootNode;
- (BOOL)shouldTerminate;
	
// Toolbar Actions
- (void)segControlClicked:(id)sender;
- (void)togglePreviewPanel;
- (void)toggleShowTagged;
// Dir Context Menu Actions
- (IBAction)setNewRoot:(id)sender;
// PreferencesController Actions
- (void)saveTableColumns;
@end
