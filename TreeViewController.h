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
@class BatchPanelController;
@class RenamePanelController;
@class TextViewerController;
@class OpenWith;
/*!
 @indexgroup ViewController
*/

/*!
 @class TreeViewController
 @brief The TreeViewController class

 @discussion    This class is the QuollEyeTree ViewController which controls:-

  Directory Window - a tree display of Directories.

  File Window - a list of Files in the currently selected Directory.
 
  Status Bar - the path of the current directory and file count.
 */

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
	BOOL currentlyLogging;
	CopyPanelController *copyPanel;
	RenamePanelController *renamePanel;
    TextViewerController *textViewer;
	BatchPanelController *batchPanel;
    OpenWith *openWithClass;    // need to hang on to class for ARC
    NSArray *filesToView;
    NSUInteger currentFileToView;
    NSInteger spinCount;
    NSOperationQueue *queue;
	NSString *targetDirectory;	// target Dir of Copy/Move/Symlink
    NSMutableArray *filesInBranch;	// a copy of Branch contents
}
@property (unsafe_unretained) NSUInteger countTaggedFiles;
@property (unsafe_unretained) IBOutlet NSTextField *taggedFilesCount;
@property (unsafe_unretained) IBOutlet NSTextView *noFiles;
@property (unsafe_unretained) IBOutlet NSSplitView *split;
@property (unsafe_unretained) IBOutlet NSScrollView *splitViewTop;
@property (unsafe_unretained) IBOutlet NSArrayController *arrayController;
@property (unsafe_unretained) IBOutlet MyOutlineView *dirTree;
@property (unsafe_unretained) IBOutlet NSTableView *fileList;
@property (unsafe_unretained) BOOL sidebyside;
@property (unsafe_unretained) IBOutlet NSPathControl *currentPath;
@property (unsafe_unretained) IBOutlet NSProgressIndicator *progress;
@property (unsafe_unretained) IBOutlet NSTextField *statusMessage;

@property (unsafe_unretained) id delegate;
@property (unsafe_unretained) NSMutableArray *filesInDir;
@property (unsafe_unretained) DirectoryItem *selectedDir;    // item to display
@property (copy) NSURL *currDir;    // binding to NSPathControl *currentPath
@property (unsafe_unretained) NSString *renameMask;

- (NSString *)getTargetFile;
- (NSString *)rootDirName;
- (void)activateTreeView;
- (void)suspendTreeView;
- (void)reloadData;
- (void)initWithDir:(DirectoryItem *)node;
- (void)setTreeRootNode:(DirectoryItem *)node;
- (DirectoryItem *)treeRootNode;
- (BOOL)shouldTerminate;
- (void)refreshCounters;

// Toolbar Actions
- (void)segControlClicked:(id)sender;
- (void)togglePreviewPanel;
- (void)toggleShowTagged;
- (void)toggleView;
// PreferencesController Actions
- (void)saveTableColumns;
@end
