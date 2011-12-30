//
//  DirectoryItem.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 31/05/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "DirectoryItem.h"
#import "FileItem.h"
#include <sys/stat.h>

@implementation DirectoryItem

@synthesize files=_files, loggedSubDirectories=_subDirectories, alias, package;

static NSMutableArray *leafNode = nil;
static NSArray *fileSortDescriptor = nil;
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
    if (self == [DirectoryItem class]) {
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
}

// This method returns the top DirectoryItem in the tree, but NOT any enclosing VolumeItem
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

// This is the main routine to populate a directory
- (NSArray *)loadDirectory:(NSString *)path error:(NSError **)error {	
	NSURL *url = [NSURL fileURLWithPath:path isDirectory:YES];
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
    newSubDir->package = YES;
    [_subDirectories sortUsingDescriptors:dirSortDescriptor];
    return YES;
}
// Create File and SubDirectory detail from an array of URLs
- (void)setFileAndDirDetails:(NSArray *)array {
	// dirs is index set which contains Directories
	NSIndexSet *dirs = [array indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
        id value = nil;
        [obj getResourceValue:&value forKey:NSURLIsPackageKey error:nil];
        if ([value boolValue])	return NO;	// exclude Packages
        [obj getResourceValue:&value forKey:NSURLIsDirectoryKey error:nil];
        if ([value boolValue])	return YES;
        // Check Alias (including Symbolic Links) to determine if these target Directories
        [obj getResourceValue:&value forKey:NSURLIsAliasFileKey error:nil];
        if ([value boolValue]) {
            FSRef fsRef;
            if (CFURLGetFSRef((CFURLRef)[array objectAtIndex:index], &fsRef)) {
                Boolean targetIsFolder, wasAliased;
                OSErr err = FSResolveAliasFileWithMountFlags(&fsRef, FALSE, &targetIsFolder, &wasAliased, kResolveAliasFileNoUI);
                if (err == noErr) {
                    if(targetIsFolder) return YES;
                }
            }
        }
        return NO;
	}];
    
	// create array of Files "fileArray" by removing dirs from array
	NSMutableArray *fileArray = [NSMutableArray new];
	[fileArray setArray:array];
    
	if([dirs count]) {
		[fileArray removeObjectsAtIndexes:dirs];	// remove dirs from fileArray, leaving Files
		if (_subDirectories == nil || _subDirectories == leafNode) {
			_subDirectories = [[NSMutableArray alloc] initWithCapacity:[dirs count]];
		}
		// Populate NSMutableArray subDirectories with contents of index set dirs
		NSUInteger index = [dirs firstIndex];
		while(index != NSNotFound)
		{
			DirectoryItem *newSubDir = [[DirectoryItem alloc]
										initWithPath:[array objectAtIndex:index]
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
        }
		[_files sortUsingDescriptors:fileSortDescriptor];
	} else {
		if (_files == nil)  _files = [[NSMutableArray alloc] initWithCapacity:1];   // allocate empty array for NSArrayController
    }
}
// copy subDirectories & files from linked entry
// If not found loads target
- (void)copyDirContent:(NSString *)linkPath {
	if (linkPath) {
		DirectoryItem *loadedPath = [self loadPath:linkPath];			
		if (loadedPath == nil) {
				_subDirectories = leafNode;
				return;
        }
		_subDirectories = [loadedPath subDirectories];
		_files = [loadedPath files];
		alias = YES;
		return;
	}
}
// get target of Symlink or Alias
- (NSString *)getTarget:(NSString *)fPath {
	NSString *resolvedPath = nil;
	// Use lstat to determine if the file is a symlink
	struct stat fileInfo;
	NSFileManager *fileManager = [NSFileManager new];
	if (lstat([fileManager fileSystemRepresentationWithPath:fPath], &fileInfo) < 0)
		return nil;
	if (S_ISLNK(fileInfo.st_mode)) {
		// Resolve the symlink component in the path
		NSError *error = nil;
		resolvedPath = [fileManager destinationOfSymbolicLinkAtPath:fPath error:&error];
		if (resolvedPath == nil) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return nil;
		}
		if ([resolvedPath isAbsolutePath])
			return resolvedPath;
		else
			return [[fPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:resolvedPath];
	}
	// Resolve alias
	CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)fPath, kCFURLPOSIXPathStyle, NO);
	FSRef fsRef;
	if (CFURLGetFSRef((CFURLRef)url, &fsRef)) {
		Boolean targetIsFolder, wasAliased;
		OSErr err = FSResolveAliasFile (&fsRef, true, &targetIsFolder, &wasAliased);
		if ((err == noErr) && wasAliased)
		{
			CFURLRef resolvedUrl = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsRef);
			if (resolvedUrl != NULL)
			{
				resolvedPath = (NSString*)CFURLCopyFileSystemPath(resolvedUrl, kCFURLPOSIXPathStyle);
				NSMakeCollectable(resolvedPath);
				CFRelease(resolvedUrl);
			}
		}
	}
	CFRelease(url);
	return resolvedPath;
}

// This routine populates all the subdirectories and files in a directory
// If alias or symbolic link copies target subdirectories and files (and loads if necessary)
- (void)loadSubDirectories {
	NSFileManager *fileManager = [NSFileManager new];
	NSString *fPath = [self fullPath];
	BOOL isDir, valid;
	NSError *error = nil;
	
	valid = [fileManager fileExistsAtPath:fPath isDirectory:&isDir];
	if (valid && isDir) {
		// array is contents of Directory
		NSArray *array = [self loadDirectory:fPath error:&error];
		if (array == nil) {
			if ([error code] == NSFileReadNoPermissionError) {
				_subDirectories = leafNode;
				return;
			}
			// This is probably a symbolic link
			[self copyDirContent:[self getTarget:fPath]];
			return;
		}
		[self setFileAndDirDetails:array];
		return;
	}
	if (valid && !isDir) {
		// Resolve alias
		[self copyDirContent:[self getTarget:fPath]];
		return;
	}
	// We should never reach this point (error excepted)
    NSLog(@"Empty? %@ ", fPath);
}

// Read directory contents and add/delete/update files and subDirs
- (void)updateDirectory {
	NSError *error = nil;
	NSString *fPath = [self fullPath];
	NSMutableArray *array = [NSMutableArray new];
	NSArray *temp = [self loadDirectory:fPath error:&error];
	if (temp == nil) {
		if ([error code] == NSFileReadNoPermissionError)	return;
		fPath = [self getTarget:fPath];	// Possible Symlink or Alias
		if (fPath)
			temp = [self loadDirectory:fPath  error:nil];
		if (temp == nil)	return;
	}
	[array setArray:temp];
	NSMutableArray *itemsToRemove = [NSMutableArray new];

	// compare logged files with array
	for (FileItem *element in _files) {
		BOOL found = NO;
		NSString *dir = [element relativePath];
		for (NSURL *url in array) {
			if ([dir compare:[url lastPathComponent] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
				found = YES;
				NSDate * tempDate;
				[url getResourceValue:&tempDate forKey:NSURLContentModificationDateKey error:nil];
				if([element.wDate isEqualToDate:tempDate]) {}
				else {
					NSNumber *size;
					[url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
					element.fileSize = size;
					element.wDate = tempDate;
				}
				[array removeObject:url];
				break;
			}
        }
		if(!found) { 
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
		NSString *dir = [element relativePath];
		for (NSURL *url in array) {
			if ([dir compare:[url lastPathComponent] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
				found = YES;
				NSDate * tempDate;
				[url getResourceValue:&tempDate forKey:NSURLContentModificationDateKey error:nil];
				if([element.wDate isEqualToDate:tempDate]) {
				}
				else {
					element.wDate = tempDate;
				}
				[array removeObject:url];
				break;
			}
		}
		if(!found) { 
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
- (void)removeSelf {
    [self.parent removeDir:self];
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
	
}

#pragma mark - Utility Methods
// look for dirName in subDirectories
- (DirectoryItem *)findDir:(NSString *)dirName {
	for (DirectoryItem *element in _subDirectories) {
		if ([[element relativePath] compare:dirName options:NSCaseInsensitiveSearch] == NSOrderedSame) {
			return element;
		}
	}
	return nil;
}

// find a Directory path in existing tree
// path is a partial path e.g. VOLUME/subdir or /Users to match DirectoryItem
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

// load (or find) a path into existing tree; return nil on failure
// path is a partial path e.g. VOLUME/subdir or /Users to match DirectoryItem
- (DirectoryItem *)loadPath:(NSString *)path {
	return [self loadPath:path expandHidden:NO];
}

#pragma mark - Key Value Properties
// Returns the array of subDirectories
// Loads subDirectories if not already loaded
- (NSArray *)subDirectories {
    if(_subDirectories == nil)
		[self loadSubDirectories];
    return _subDirectories;
}
- (DirectoryItem *)directoryAtIndex:(NSUInteger)n {
    return [[self subDirectories] objectAtIndex:n];
}
- (NSInteger)numberOfSubDirs {
    NSArray *tmp = [self subDirectories];
    return (tmp == leafNode) ? (0) : [tmp count];
}

- (void)subBranch:(NSArray *)directories accumulatedDirs:(NSMutableArray **)fileArrayInBranch {
    NSMutableArray *accumulatedFiles = *fileArrayInBranch;
    for (DirectoryItem *node in directories) {
        NSArray *filesInNode = [node files];
        if (filesInNode) {
            if (![accumulatedFiles containsObject:filesInNode])   // if not already in branch
                [accumulatedFiles addObject:filesInNode];
        }
        if([node loggedSubDirectories])
            [self subBranch:[node subDirectories] accumulatedDirs:fileArrayInBranch];
    }
}
- (NSMutableArray *)filesInBranch {
	NSMutableArray *fileArrayInBranch = [NSMutableArray new];
    if ([self files])    [fileArrayInBranch addObject:[self files]];
    [self subBranch:_subDirectories accumulatedDirs:&fileArrayInBranch];
	NSMutableArray *branch = [NSMutableArray new];
    for (NSArray *filesInNode in fileArrayInBranch) {
        [branch addObjectsFromArray:filesInNode];
    }
	[branch sortUsingDescriptors:fileSortDescriptor];
	return 	branch;
}

@end
