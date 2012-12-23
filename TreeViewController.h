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
	NSString *targetDirectory;	// target Dir of Copy/Move/Symlink
}
@property (unsafe_unretained) IBOutlet NSTextView *noFiles;
@property (unsafe_unretained) IBOutlet NSSplitView *split;
@property (unsafe_unretained) IBOutlet NSScrollView *splitViewTop;
@property (unsafe_unretained) IBOutlet NSArrayController *arrayController;
@property (unsafe_unretained) IBOutlet MyOutlineView *dirTree;
@property (unsafe_unretained) IBOutlet NSTableView *fileList;
@property (unsafe_unretained) IBOutlet NSPathControl *currentPath;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *progress;
@property (unsafe_unretained) IBOutlet NSTextField *statusMessage;

@property (unsafe_unretained) id delegate;
@property (unsafe_unretained) NSMutableArray *filesInDir;
@property (unsafe_unretained) DirectoryItem *selectedDir;    // item to display
@property (copy) NSURL *currDir;    // binding to NSPathControl *currentPath

- (NSString *)getTargetFile;
- (NSString *)rootDirName;
- (void)activateTreeView;
- (void)reloadData;
- (void)initWithDir:(DirectoryItem *)node;
- (void)setTreeRootNode:(DirectoryItem *)node;
- (DirectoryItem *)treeRootNode;
- (BOOL)shouldTerminate;
	
// Toolbar Actions
- (void)segControlClicked:(id)sender;
- (void)togglePreviewPanel;
- (void)toggleShowTagged;
// PreferencesController Actions
- (void)saveTableColumns;
@end
