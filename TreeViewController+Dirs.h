//
//  TreeViewController+Dirs.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 2/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeViewController.h"

@interface TreeViewController(Dirs)

// Menu Actions
- (void)showAllFiles:(BOOL)inRoot tagged:(BOOL)tagged;
- (void)copyDirTo;
- (void)moveDirTo;
- (void)moveDirToTrash;
- (void)pasteURL;
- (void)makeDir;
- (void)renameDir;
- (void)compareDir;
- (void)toggleDir:(BOOL)all;
- (void)unhideBranch;
// Context Menu Actions
- (IBAction)copyDir:(id)sender;
- (IBAction)copyDirToClipboard:(id)sender;
- (IBAction)openDirectory:(id)sender;
- (IBAction)revealDirInFinder:(id)sender;
- (IBAction)openDirInNewTab:(id)sender;
- (IBAction)openDirInTerminal:(id)sender;
- (IBAction)getDirInfo:(id)sender;
- (IBAction)addDirToSidebar:(id)sender;
- (IBAction)showTargetDir:(id)sender;
- (IBAction)symlinkToDir:(id)sender;

@end
