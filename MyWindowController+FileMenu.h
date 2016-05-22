//
//  MyWindowController+FileMenu.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 9/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyWindowController.h"


@interface MyWindowController(FileMenu)
// Dir Menu Actions
- (IBAction)showFilesInBranch:(id)sender;
- (IBAction)showAllFiles:(id)sender;
- (IBAction)copyDirTo:(id)sender;
- (IBAction)moveDirToTrash:(id)sender;
- (IBAction)moveDirTo:(id)sender;
- (IBAction)makeDir:(id)sender;
- (IBAction)renameDir:(id)sender;
- (IBAction)compareDir:(id)sender;
- (IBAction)toggleHidden:(id)sender;
- (IBAction)toggleAllHidden:(id)sender;
- (IBAction)pasteURL:(id)sender;
// File Menu Actions
- (IBAction)tagOneFile:(id)sender;
- (IBAction)untagOneFile:(id)sender;
- (IBAction)tagAllFiles:(id)sender;
- (IBAction)untagAllFiles:(id)sender;
- (IBAction)invertTaggedFiles:(id)sender;

- (IBAction)moveToTrash:(id)sender;
- (IBAction)moveTaggedToTrash:(id)sender;
- (IBAction)deleteTagged:(id)sender;
- (IBAction)putBack:(id)sender;
- (IBAction)copyFileTo:(id)sender;
- (IBAction)moveFileTo:(id)sender;
- (IBAction)renameFile:(id)sender;
- (IBAction)copyTaggedFilesTo:(id)sender;
- (IBAction)moveTaggedFilesTo:(id)sender;
- (IBAction)renameTaggedFilesTo:(id)sender;
- (IBAction)compareFile:(id)sender;
- (IBAction)editFile:(id)sender;
- (IBAction)editTaggedFiles:(id)sender;
- (IBAction)batchForTaggedFiles:(id)sender;
// Dir Context & Menu Actions
- (IBAction)openDirectory:(id)sender;
- (IBAction)copyDir:(id)sender;
- (IBAction)revealDirInFinder:(id)sender;
- (IBAction)getDirInfo:(id)sender;
// File Context & Menu Actions
- (IBAction)openFile:(id)sender;
- (IBAction)copyTaggedFiles:(id)sender;
- (IBAction)revealFileInFinder:(id)sender;
- (IBAction)getFileInfo:(id)sender;
@end
