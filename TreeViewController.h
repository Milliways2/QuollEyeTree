//
//  TreeViewController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 13/06/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeViewControllerDelegate.h"

@class DirectoryItem;
@class CopyPanelController;
@class RenamePanelController;
@class TextViewerController;
@class OpenWith;

@interface TreeViewController : NSViewController <NSMenuDelegate> {
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

@property (strong) IBOutlet NSSplitView *split;
@property (strong) IBOutlet NSScrollView *splitViewTop;
@property (strong) IBOutlet NSArrayController *arrayController;
@property (strong) IBOutlet NSOutlineView *dirTree;
@property (strong) IBOutlet NSTableView *fileList;
@property (strong) IBOutlet NSPathControl *currentPath;
@property (strong) IBOutlet NSProgressIndicator *progress;

@property (strong) id delegate;
@property (strong) NSMutableArray *filesInDir;
@property (strong) DirectoryItem *selectedDir;    // item to display
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
