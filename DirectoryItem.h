//
//  DirectoryItem.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 31/05/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileSystemItem.h"

@interface DirectoryItem: FileSystemItem {
    NSMutableArray *_subDirectories;
    NSMutableArray *_files;
	BOOL unHideDir;
	BOOL unHideAllDir;
}

@property (strong, readonly) NSMutableArray *files;
@property (strong, readonly) NSArray *loggedSubDirectories;

- (DirectoryItem *)rootDir;
- (id)initRootWithPath:(NSURL *)path;

- (NSInteger)numberOfSubDirs;	// Returns 0 for leaf nodes
- (DirectoryItem *)directoryAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes
- (NSMutableArray *)subDirectories;
- (NSUInteger)sizeOfFiles;
- (BOOL)isPathLoaded;

- (DirectoryItem *)findPathInDir:(NSString *)path;
- (DirectoryItem *)loadPath:(NSString *)path;
- (DirectoryItem *)loadPath:(NSString *)path expandHidden:(BOOL)expandHidden;
- (void)logDirPlus1;
- (void)updateDirectory;
- (void)releaseDir;
- (void)removeDir:(DirectoryItem *)node;
- (void)moveItem:(FileSystemItem *)node;
- (BOOL)convertPackageToDirectory:(FileSystemItem *)fNode;
- (void)toggleHidden:(BOOL)all;
- (void)cloneHidden:(DirectoryItem *)dir;
- (BOOL)showHidden;
- (BOOL)showDotted;

@end
