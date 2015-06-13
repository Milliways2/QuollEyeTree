//
//  DirectoryItem.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 31/05/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileSystemItem.h"

/*! @class DirectoryItem

 @brief The DirectoryItem class

 @discussion    This is a class containing properties/methods to support Directories.
 */
@interface DirectoryItem: FileSystemItem {
    NSMutableArray *_subDirectories;
    NSMutableArray *_files;
	BOOL unHideDir;
	BOOL unHideAllDir;
}

@property (strong, readonly) NSMutableArray *files;
@property (strong, readonly) NSArray *loggedSubDirectories;

/*! @brief This method returns the top DirectoryItem in the tree, but NOT any enclosing VolumeItem.
 @return DirectoryItem top Directory.
 */
- (DirectoryItem *)rootDir;
- (id)initRootWithPath:(NSURL *)path;

/*! @brief Number of subDirectories
 @discussion	Loads subDirectories if not already loaded
 @return NSInteger number of subDirectories ( 0 for leaf nodes).
 */
- (NSInteger)numberOfSubDirs;	// Returns 0 for leaf nodes

/*! @brief Returns a Boolean value that indicates whether the directory is expandable.
 @discussion	Loads subDirectories if not already loaded
 @return YES if directory can be expanded to display its subDirectories, otherwise NO.
 */
- (BOOL)isDirectoryExpandable;
- (DirectoryItem *)directoryAtIndex:(NSUInteger)n; // Invalid to call on leaf nodes
/*! @brief Loads subDirectories if not already loaded
 @return NSArray array of subDirectories.
 */
- (NSMutableArray *)subDirectories;
/*! @brief Compute total of logged files
 @return total size of logged files.
 */
- (NSUInteger)sizeOfFiles;
/*! @brief	Check if subDirectories loaded
 @discussion	Needs to access ivar to prevent automatic loading
 */
- (BOOL)isPathLoaded;
/*! @brief	Check if sub-subDirectories loaded
 */
- (BOOL)isDirPlus1Loaded;

/*! @brief	Find a Directory path in existing tree
 @param	path a partial path e.g. VOLUME/subdir or /Users to match DirectoryItem
 */
- (DirectoryItem *)findPathInDir:(NSString *)path;
/*! @brief	load (or find) a path into existing tree; return nil on failure
 @discussion Loads all intermediate directories back to root or Volume
 @param	path a partial path e.g. VOLUME/subdir or /Users to match DirectoryItem
 @return DirectoryItem or nil on failure
 @see loadPath:expandHidden:
 */
- (DirectoryItem *)loadPath:(NSString *)path;
/*! @brief	load (or find) a path into existing tree; return nil on failure
 @discussion Loads all intermediate directories back to root or Volume
 @param	path a partial path e.g. VOLUME/subdir or /Users to match DirectoryItem
 @param expandHidden load "hidden" items
 @return DirectoryItem or nil on failure
 */
- (DirectoryItem *)loadPath:(NSString *)path expandHidden:(BOOL)expandHidden;
/*! @brief	Log Directory and 1st level subDirectories
 */
- (void)logDirPlus1;
/*! @brief	Log Directory (if not already loaded)
 @return DirectoryItem
 */
- (DirectoryItem *)logDir;
/*! @brief	This method reads directory contents and add/delete/update files and subDirs
 */
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
