//
//  TreeViewController+Files.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 1/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeViewController.h"

@interface TreeViewController(Files) 

// Menu Actions
- (void)tagOneFile;
- (void)untagOneFile;
- (void)tagAllFiles;
- (void)untagAllFiles;
- (void)invertTaggedFiles;

- (void)moveToTrash;
- (void)moveTaggedToTrash;
- (void)copyFileTo;
- (void)moveFileTo;
- (void)copyTaggedFilesTo;
- (void)moveTaggedFilesTo;
- (void)renameTaggedFilesTo;
- (void)renameFile;

// Context Menu Actions
- (IBAction)openFile:(id)sender;
- (IBAction)copyFileToClipboard:(id)sender;
- (IBAction)copyFile:(id)sender;
- (IBAction)copyTaggedFiles:(id)sender;
- (IBAction)revealFileInFinder:(id)sender;
- (IBAction)showPackageContents:(id)sender;
- (IBAction)showTarget:(id)sender;
- (IBAction)symlinkToFile:(id)sender;
- (IBAction)getFileInfo:(id)sender;
@end

