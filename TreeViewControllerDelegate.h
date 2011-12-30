//
//  TreeViewControllerDelegate.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 5/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class TreeViewController;
@class DirectoryItem;

@protocol TreeViewControllerDelegate
- (void)treeViewController:(TreeViewController *)tvc tabState:(BOOL)state;
- (void)treeViewController:(TreeViewController *)tvc filterValue:(NSString *)string;
- (void)treeViewController:(TreeViewController *)tvc setPanelData:(NSArray *)array;
- (void)treeviewDidEnterFileWindow:(TreeViewController *)tvc;
- (void)treeviewDidEnterDirWindow:(TreeViewController *)tvc;
- (void)treeViewController:(TreeViewController *)tvc rootChangedInTreeView:(NSString *)rootDirName;
- (void)treeViewController:(TreeViewController *)tvc pauseRefresh:(BOOL)pause;
- (void)treeViewController:(TreeViewController *)tvc addNewTabAtDir:(DirectoryItem *)dir;
- (void)treeViewController:(TreeViewController *)tvc addToSidebar:(NSString *)directory;
- (void)treeViewController:(TreeViewController *)tvc didRemoveDirectory:(NSString *)directory;

@end
