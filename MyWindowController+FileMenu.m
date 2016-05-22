//
//  MyWindowController+FileMenu.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 9/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "MyWindowController+FileMenu.h"
#import "TreeViewController.h"
#import "TreeViewController+Files.h"
#import "TreeViewController+Dirs.h"


@implementation MyWindowController(FileMenu)

#pragma mark File & Dir Menu Actions
// File Menu Actions
- (IBAction)tagOneFile:(id)sender {
	[currentTvc tagOneFile];
}
- (IBAction)untagOneFile:(id)sender {
	[currentTvc untagOneFile];
}
- (IBAction)tagAllFiles:(id)sender {
	[currentTvc tagAllFiles];
}
- (IBAction)untagAllFiles:(id)sender {
	[currentTvc untagAllFiles];
}
- (IBAction)invertTaggedFiles:(id)sender {
	[currentTvc invertTaggedFiles];
}

- (IBAction)moveToTrash:(id)sender {
	[currentTvc moveToTrash];
}
- (IBAction)moveTaggedToTrash:(id)sender {
	[currentTvc moveTaggedToTrash];
}
- (IBAction)deleteTagged:(id)sender {
	[currentTvc deleteTagged];
}
- (IBAction)putBack:(id)sender {
// This is a dummy so validateMenuItem: will populate the putBackMenu
}
- (IBAction)copyFileTo:(id)sender {
	[currentTvc copyFileTo];
}
- (IBAction)moveFileTo:(id)sender {
	[currentTvc moveFileTo];
}
- (IBAction)renameFile:(id)sender {
	[currentTvc renameFile];
}
- (IBAction)copyTaggedFilesTo:(id)sender {
	[currentTvc copyTaggedFilesTo];
}
- (IBAction)moveTaggedFilesTo:(id)sender {
	[currentTvc moveTaggedFilesTo];
}
- (IBAction)compareFile:(id)sender {
	[currentTvc compareFile];
}
- (IBAction)editFile:(id)sender {
	[currentTvc editFile];
}
- (IBAction)editTaggedFiles:(id)sender {
	[currentTvc editTaggedFiles];
}

- (IBAction)showFilesInBranch:(id)sender {	//?
	[currentTvc showAllFiles:NO tagged:NO];
}
- (IBAction)showAllFiles:(id)sender {	//?
	[currentTvc showAllFiles:YES tagged:NO];
}
- (IBAction)renameTaggedFilesTo:(id)sender {
	[currentTvc renameTaggedFilesTo];
}

- (IBAction)batchForTaggedFiles:(id)sender {
	[currentTvc batchForTaggedFiles];
}


// Dir Menu Actions
- (IBAction)copyDirTo:(id)sender {
	[currentTvc copyDirTo];
}
- (IBAction)moveDirTo:(id)sender {
	[currentTvc moveDirTo];
}
- (IBAction)moveDirToTrash:(id)sender {
	[currentTvc moveDirToTrash];
}
- (IBAction)makeDir:(id)sender {
	[currentTvc makeDir];
}
- (IBAction)renameDir:(id)sender{
	[currentTvc renameDir];
}
- (IBAction)compareDir:(id)sender {
	[currentTvc compareDir];
}
- (IBAction)toggleHidden:(id)sender {
	[currentTvc toggleDir:NO];
}
- (IBAction)toggleAllHidden:(id)sender {
	[currentTvc toggleDir:YES];
}
- (IBAction)unhideBranch:(id)sender {
	[currentTvc unhideBranch];
}
- (IBAction)pasteURL:(id)sender {
	[currentTvc pasteURL];
}
// Dir Context & Menu Actions
- (IBAction)openDirectory:(id)sender {
	[currentTvc openDirectory:self];
}
- (IBAction)copyDir:(id)sender {
	[currentTvc copyDir:self];
}
- (IBAction)revealDirInFinder:(id)sender {
	[currentTvc revealDirInFinder:self];
}
- (IBAction)getDirInfo:(id)sender {
	[currentTvc getDirInfo:self];
}
// File Context & Menu Actions
- (IBAction)openFile:(id)sender {
	[currentTvc openFile:sender];
}
- (IBAction)copyTaggedFiles:(id)sender {
	[currentTvc copyTaggedFiles:sender];
}
- (IBAction)revealFileInFinder:(id)sender {
	[currentTvc revealFileInFinder:sender];
}
- (IBAction)getFileInfo:(id)sender {
	[currentTvc getFileInfo:sender];
}

@end
