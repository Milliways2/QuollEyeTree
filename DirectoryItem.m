//
//  DirectoryItem.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 31/05/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "DirectoryItem.h"
#import "FileItem.h"
#import "volume.h"
#import "alias.h"
#import "folderSize.h"
#import "volumeForPath.h"

@interface DirectoryItem ()
/*! @brief	This is the main (private) method to read the contents of a directory.
 @param	dirPath	directory
 @internal
 @return	array of URL.
 */
- (NSArray *)readDirectory:(NSString *)dirPath error:(NSError **)error;
/*!	@brief	This private method creates File and SubDirectory detail.
 @internal
 @param  arrayUrl array of URL
 */
- (void)setFileAndDirDetails:(NSArray *)arrayUrl;
/*!	@brief	This private method populates all the subdirectories and files in a directory
 @internal
 @discussion	If alias or symbolic link copies target subdirectories and files (and loads if necessary)
 */
- (void)loadSubDirectories;
/*!	This private method look for dirName in subDirectories
 @internal
 @param  dirName directory name
 @return DirectoryItem (if found) or nil
 */
- (DirectoryItem *)findDir:(NSString *)dirName;
@end
@implementation DirectoryItem
@synthesize files=_files, loggedSubDirectories=_subDirectories;

static NSMutableArray *leafNode = nil;
NSArray *fileSortDescriptor = nil;
static NSArray *dirSortDescriptor = nil;
static BOOL showHiddenFiles = NO;
static NSArray *properties = nil;

+ (void)loadPreferences {
	// Read default sortDescriptor from Preferences
	fileSortDescriptor = [NSArray arrayWithObject:[[NSSortDescriptor alloc]
                                                   initWithKey:[[NSUserDefaults standardUserDefaults] stringForKey:PREF_SORT_FIELD]
                                                   ascending:[[NSUserDefaults standardUserDefaults] boolForKey:PREF_SORT_DIRECTION] ]];
	showHiddenFiles = [[NSUserDefaults standardUserDefaults] boolForKey:PREF_HIDDEN_FILES];
}
+ (void)initialize {
	leafNode = [[NSMutableArray alloc] init];
	[self loadPreferences];
	properties = [NSArray arrayWithObjects:
				  NSURLNameKey,
				  NSURLFileSizeKey, NSURLIsAliasFileKey, NSURLIsPackageKey,
				  NSURLIsDirectoryKey, NSURLIsSymbolicLinkKey, NSURLIsRegularFileKey,
				  NSURLCreationDateKey, NSURLContentModificationDateKey,
				  NSURLLocalizedTypeDescriptionKey, nil];
	dirSortDescriptor = [NSArray arrayWithObject:
						 [[NSSortDescriptor alloc] initWithKey:COLUMNID_NAME
													 ascending:YES
													  selector:@selector(localizedStandardCompare:)]];
}

- (DirectoryItem *)rootDir {
	if (parent == nil) return self;
	if([parent isKindOfClass:[DirectoryItem class]]) {
		DirectoryItem *root = parent;
		while ([root->parent isKindOfClass:[DirectoryItem class]]) {
			root = root->parent;	// Method parent returns self for root so we need to access ivar
		}
		return (DirectoryItem *)root;
	}
	return self;
}

- (id)initRootWithPath:(NSURL *)path {
	return [self initWithPath:path parent:nil];
}

- (NSURL *)url {
    return [NSURL fileURLWithPath:[self fullPath] isDirectory:YES];
}
- (BOOL) isLeafNode {
	return _subDirectories == leafNode;
}

- (NSArray *)readDirectory:(NSString *)dirPath error:(NSError **)error {
	NSURL *url = [NSURL fileURLWithPath:dirPath isDirectory:YES];
	NSArray *array = [[NSFileManager new]
					  contentsOfDirectoryAtURL:url
					  includingPropertiesForKeys:properties
					  options:(NSDirectoryEnumerationSkipsPackageDescendants |
							   ((showHiddenFiles | unHideDir| unHideAllDir) ? 0 : NSDirectoryEnumerationSkipsHiddenFiles))
					  error:error];
	if (unHideDir) {
		NSIndexSet *unDotted = [array indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
			NSString *name;
			[obj getResourceValue:&name forKey:NSURLNameKey error:nil];
			if ([name characterAtIndex:0] == '.')	return NO;	// exclude .files
			return YES;
		}];
		return [array objectsAtIndexes:unDotted];
	}
	return array;
}
- (BOOL)showHidden {
    return (showHiddenFiles | unHideDir);
}
- (BOOL)showDotted {
    return (showHiddenFiles | unHideAllDir);
}
- (void)toggleHidden:(BOOL)all {
    if (showHiddenFiles)
        return;
    if (all) {
        unHideDir = NO;
        unHideAllDir = !unHideAllDir;
        return;
    }
    unHideAllDir = NO;
    unHideDir = !unHideDir;
}
- (void)cloneHidden:(DirectoryItem *)dir {
    unHideAllDir = dir->unHideAllDir;
    unHideDir = dir->unHideDir;
}
- (BOOL)convertPackageToDirectory:(FileSystemItem *)fNode {
    NSURL *fUrl = fNode.url;
    id value = nil;
    [fUrl getResourceValue:&value forKey:NSURLIsDirectoryKey error:nil];
    if (![value boolValue])	return NO;

    if (_subDirectories == nil || _subDirectories == leafNode) {
        _subDirectories = [[NSMutableArray alloc] initWithCapacity:1];
    }
    DirectoryItem *newSubDir = [[DirectoryItem alloc]
                                initWithPath:fUrl
                                parent:self];
    [_subDirectories addObject:newSubDir];
    [_subDirectories sortUsingDescriptors:dirSortDescriptor];
    return YES;
}
- (void)setFileAndDirDetails:(NSArray *)arrayUrl {
	// dirs is index set which contains Directories
	NSIndexSet *dirs = [arrayUrl indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
        id value = nil;
        [obj getResourceValue:&value forKey:NSURLIsPackageKey error:nil];
        if ([value boolValue])	return NO;	// exclude Packages
        [obj getResourceValue:&value forKey:NSURLIsDirectoryKey error:nil];
        if ([value boolValue])	return YES;
        // Check Alias (including Symbolic Links) to determine if these target Directories
        [obj getResourceValue:&value forKey:NSURLIsAliasFileKey error:nil];
        if ([value boolValue])
			return isAliasFolder([arrayUrl objectAtIndex:index]);
        return NO;
	}];

	// create array of Files "fileArray" by removing dirs from array
	NSMutableArray *fileArray = [NSMutableArray new];
	[fileArray setArray:arrayUrl];

	if([dirs count]) {
		[fileArray removeObjectsAtIndexes:dirs];	// remove dirs from fileArray, leaving Files
		if (_subDirectories == nil || _subDirectories == leafNode) {
			_subDirectories = [[NSMutableArray alloc] initWithCapacity:[dirs count]];
		}
		// Populate NSMutableArray subDirectories with contents of index set dirs
		NSUInteger index = [dirs firstIndex];
		while(index != NSNotFound) {
			DirectoryItem *newSubDir = [[DirectoryItem alloc]
										initWithPath:[arrayUrl objectAtIndex:index]
										parent:self];
			[_subDirectories addObject:newSubDir];
			index=[dirs indexGreaterThanIndex: index];
		}
		[_subDirectories sortUsingDescriptors:dirSortDescriptor];
	} else {
		if (_subDirectories == nil)	_subDirectories = leafNode;
	}

	if([fileArray count]) {
		if (_files == nil) {
			_files = [[NSMutableArray alloc] initWithCapacity:[fileArray count]];
		}
		// Populate NSMutableArray files with contents of fileArray
		for (NSURL *element in fileArray) {
                FileItem *newFile = [[FileItem alloc]
                                     initWithPath:element
                                     parent:self];
                NSNumber *size;
                [element getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
                newFile.fileSize = size;
                [_files addObject:newFile];
			if (newFile.isPackage) {
				dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
				dispatch_async(aQueue, ^{
					newFile.fileSize = folderSize(element);
				});

			}
        }
		[_files sortUsingDescriptors:fileSortDescriptor];
	} else {
		if (_files == nil)  _files = [[NSMutableArray alloc] initWithCapacity:1];   // allocate empty array for NSArrayController
    }
}
/*! @brief	This (private) method copies subDirectories & files from linked entry.
 @discussion	Called for Symlink and Alias. If not found loads target.
 @param	linkPath	directory path
 */
- (void)copyDirContent:(NSString *)linkPath {
	if (linkPath) {
		DirectoryItem *loadedPath = [self loadPath:linkPath];
		if (loadedPath == nil) {
			loadedPath = locateOrAddDirectoryInVolumes(linkPath);
			if (loadedPath == nil) {
				_subDirectories = leafNode;
				return;
			}
        }
		_subDirectories = [loadedPath subDirectories];
		_files = [loadedPath files];
		return;
	}
}

- (void)loadSubDirectories {
	NSFileManager *fileManager = [NSFileManager new];
	NSString *fPath = [self fullPath];
	BOOL isDir;
	NSError *error = nil;

	if ([fileManager fileExistsAtPath:fPath isDirectory:&isDir]) {
		if (isDir) {
			// arrayUrl is contents of Directory
			NSArray *arrayUrl = [self readDirectory:fPath error:&error];
			if (arrayUrl) {
				[self setFileAndDirDetails:arrayUrl];
				return;
			}
			if ([error code] == NSFileReadNoPermissionError) {
				_subDirectories = leafNode;
				return;	// User does not have permission to read this directory
			}
			// This is probably a symbolic link
		}
			[self copyDirContent:getTarget(fPath)];	// Get target of Alias/symlink
			return;
	}
	// We should never reach this point (error excepted)
    NSLog(@"Empty? %@ ", fPath);
}
- (void)logDirPlus1 {
	NSArray *tempArray = [NSArray arrayWithArray:self.subDirectories];
	for (DirectoryItem *dir in tempArray) {
		[dir subDirectories];
	}
}
- (DirectoryItem *)logDir {
	if (![self isPathLoaded])
		[self subDirectories];
	return self;
}

- (void)updateDirectory {
	NSError *error = nil;
	NSString *fPath = [self fullPath];
	NSMutableArray *array = [NSMutableArray new];
	NSArray *temp = [self readDirectory:fPath error:&error];
	if (temp == nil) {
		if ([error code] == NSFileReadNoPermissionError)	return;
		fPath = getTarget(fPath);	// Possible Symlink or Alias
		if (fPath)
			temp = [self readDirectory:fPath  error:nil];
		if (temp == nil)	return;
	}
	[array setArray:temp];
	NSMutableArray *itemsToRemove = [NSMutableArray new];

	// compare logged files with array
	for (FileItem *element in _files) {
		BOOL found = NO;
		NSURL *url = nil;
		NSString *dir = [element relativePath];
		for (url in array) {
			if ([dir compare:[url lastPathComponent] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
				found = YES;
				NSDate * tempDate;
				[url getResourceValue:&tempDate forKey:NSURLContentModificationDateKey error:nil];
				if([element.wDate isEqualToDate:tempDate]) {}
				else {
					element.wDate = tempDate;
					if (element.isPackage) {
						dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
						dispatch_async(aQueue, ^{
							element.fileSize = folderSize(element.url);
						});
					} else {
						NSNumber *size;
						[url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
						element.fileSize = size;
					}
				}
				break;
			}
        }
		if(found) {
			[array removeObject:url];
		} else {
			[itemsToRemove addObject:element];	// add element to itemsToRemove
		}
	}

	if([itemsToRemove count]) {
		[_files removeObjectsInArray:itemsToRemove];
		[itemsToRemove removeAllObjects];
	}

	// compare logged subDirectories with array
	for (DirectoryItem *element in _subDirectories) {
		BOOL found = NO;
		NSURL *url = nil;
		NSString *dir = [element relativePath];
		for (url in array) {
			if ([dir compare:[url lastPathComponent] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
				found = YES;
				NSDate *tempDate;
				[url getResourceValue:&tempDate forKey:NSURLContentModificationDateKey error:nil];
				if(![element.wDate isEqualToDate:tempDate]) {
					element.wDate = tempDate;
				}	
				break;
			}
		}
		if(found) {
			[array removeObject:url];
		} else {
			[itemsToRemove addObject:element];	// add element to itemsToRemove
		}
	}
	if([itemsToRemove count]) {
		NSMutableArray *dirsRemoved = [NSMutableArray new];
		for (DirectoryItem *element in itemsToRemove) {
			[dirsRemoved addObject:[element fullPath]];
		}
		[_subDirectories removeObjectsInArray:itemsToRemove];
		if([_subDirectories count] == 0) {
			_subDirectories = leafNode;	// in case all subdirs removed
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:DirectoryItemDidRemoveDirectoriesNotification object:self
														  userInfo:[NSDictionary dictionaryWithObject:dirsRemoved
																							   forKey:@"DirectoriesRemoved"]];
	}
	// new items to add
	if([array count]) {
		[self setFileAndDirDetails:array];
	}
    [_subDirectories sortUsingDescriptors:dirSortDescriptor];
    [_files sortUsingDescriptors:fileSortDescriptor];
}
- (void)removeDir:(DirectoryItem *)node {
    [_subDirectories removeObject:node];
    if([_subDirectories count] == 0) {
        _subDirectories = leafNode;	// in case all subdirs removed
    }
}
- (void)moveItem:(FileSystemItem *)node {
	node.parent = self;	// reparent node to this directory
	if ([node isKindOfClass:[FileItem class]]) {
		[_files addObject:node];
		[_files sortUsingDescriptors:fileSortDescriptor];
	} else {
		if (_subDirectories == nil || _subDirectories == leafNode) {
			_subDirectories = [[NSMutableArray alloc] initWithCapacity:1];
		}
		[_subDirectories addObject:node];
		[_subDirectories sortUsingDescriptors:dirSortDescriptor];
	}
}
- (void)releaseDir {
    if(!self.isAlias) {
        for (DirectoryItem *subDir in _subDirectories) {
			subDir->_subDirectories = NULL;
			[subDir.files removeAllObjects];
		}
	}
}

#pragma mark - Utility Methods
/*! @internal */
- (DirectoryItem *)findDir:(NSString *)dirName {
	for (DirectoryItem *element in _subDirectories) {
		if ([[element relativePath] compare:dirName options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			return element;
		}
	}
	return nil;
}

- (DirectoryItem *)findPathInDir:(NSString *)path {
	NSArray *pathComponents = [path pathComponents];
	NSUInteger index;
	DirectoryItem *item = self;
	DirectoryItem *itemFound = nil;
	if ([[item relativePath] compare:[pathComponents objectAtIndex:0] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		for(index = 1; index < [pathComponents count]; index++) {
			itemFound = [item findDir:[pathComponents objectAtIndex:index]];
			if(itemFound)	item = itemFound;
			else		return nil;	// Path not found
		}
		return item;
	}
	return nil;	// Base does not Match
}
// Check if subDirectories loaded - needs to access ivar to prevent automatic loading
- (BOOL)isPathLoaded {
	return _subDirectories != nil;
}
// Check if subsubDirectories loaded
- (BOOL)isDirPlus1Loaded {
	for (DirectoryItem *dir in self.loggedSubDirectories) {
		if (![dir isPathLoaded])
			return NO;
	}
	return YES;
}
- (DirectoryItem *)loadPath:(NSString *)path expandHidden:(BOOL)expandHidden {
	NSArray *pathComponents = [path pathComponents];
	NSUInteger index;
	DirectoryItem *item = [self rootDir];
	DirectoryItem *itemFound = nil;
	if ([[item relativePath] compare:[pathComponents objectAtIndex:0] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
		for(index = 1; index < [pathComponents count]; index++) {
			itemFound = [item findDir:[pathComponents objectAtIndex:index]];
			if(itemFound)
				item = itemFound;	// found existing
			else {	// not found, try to load
                if([item subDirectories] == nil)    // ????
                    [item loadSubDirectories];	// load dir
				itemFound = [item findDir:[pathComponents objectAtIndex:index]];
                if(itemFound)
					item = itemFound;
				else {
                    if (!expandHidden)   return nil;	// Directory does not exist
                    NSURL *url = [[item url] URLByAppendingPathComponent:[pathComponents objectAtIndex:index]];
                    id value = nil;
                    [url getResourceValue:&value forKey:NSURLIsHiddenKey error:nil];
                    if ([value boolValue]) {
                        if ([[pathComponents objectAtIndex:index] characterAtIndex:0] == '.')
                            [item toggleHidden:YES];
                        else
                            [item toggleHidden:NO];
                        [item updateDirectory];
                        itemFound = [item findDir:[pathComponents objectAtIndex:index]];
                        if(itemFound)
                            item = itemFound;
                        else		return nil;	// Directory does not exist
                    }
                }
			}
		}
		return item;
	}
	return nil;	// Base does not Match
}

- (DirectoryItem *)loadPath:(NSString *)path {
	return [self loadPath:path expandHidden:NO];
}

#pragma mark - Key Value Properties
- (NSArray *)subDirectories {
    if(_subDirectories == nil)
		[self loadSubDirectories];	//load subDirectories if not already loaded
    return _subDirectories;
}
- (DirectoryItem *)directoryAtIndex:(NSUInteger)n {
    return [[self subDirectories] objectAtIndex:n];
}
- (NSInteger)numberOfSubDirs {
    NSArray *tmp = [self subDirectories];
    return (tmp == leafNode) ? (0) : [tmp count];
}
- (NSUInteger)sizeOfFiles {
	NSUInteger totalSize = 0;
	for (FileItem *file in [self files]) {
		totalSize += [file.fileSize unsignedLongValue];
	}
    return  totalSize;
}
// !!!:	Does not expand Alias (in progress)
- (BOOL)isDirectoryExpandable {
	if(_subDirectories) {	// already loaded; check if subDirectories exist
		return (_subDirectories == leafNode ? NO : [_subDirectories count]>0);
	}
	return [[self subDirectories] count]>0;	// Log Directory
}

@end
