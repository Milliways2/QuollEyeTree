//
//  TreeViewController+Copy.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 20/12/11.
//  Copyright 2011-2013 Ian Binnie. All rights reserved.
//
#include <stdio.h>
#include <sys/stat.h>

#import "TreeViewController+Copy.h"
#import "MyWindowController.h"
#import "DirectoryItem.h"
#import "volume.h"
#import "FileItem.h"
#import "CopyPanelController.h"
#import "RenamePanelController.h"
#import "BatchPanelController.h"
#import "NSString+Rename.h"
#import "volumeForPath.h"
@interface TreeViewController(Dirs)
- (void)updateSelectedDir;
@end
@interface TreeViewController(Files)	//2015-07-09
- (NSArray *)taggedFiles;
@end

static void removeItemForPath(NSString *path) {
    NSString *parentDir = [path stringByDeletingLastPathComponent];
    DirectoryItem *targetDir = findPathInVolumes(parentDir);
    if(targetDir) {
        NSString *itemName = [path lastPathComponent];
        for (DirectoryItem *element in targetDir.loggedSubDirectories) {
            if ([[element relativePath] compare:itemName options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                [targetDir.subDirectories removeObject:element];
                return;
            }
        }
        for (FileItem *element in targetDir.files) {
            if ([[element relativePath] compare:itemName options:NSCaseInsensitiveSearch] == NSOrderedSame) {
                [targetDir.files removeObject:element];
                return;
            }
        }
    }
}
static BOOL removeTarget(NSString *target, NSFileManager *fileManager) {
	NSError *error = nil;
    if([fileManager removeItemAtPath:target error:&error]) {
        removeItemForPath(target);
        return YES;
    }
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
    return NO;
}
static BOOL createTargetDir(NSString *targetDir, NSFileManager *fileManager) {
	NSError *error = nil;
    if([fileManager createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:&error]) {
        return YES;
    }
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
    return NO;
}

@implementation TreeViewController(Copy)

- (void)startSpinner {
    if (spinCount++ == 0) {
        [self.progress startAnimation:self];
    }
}
- (void)stopSpinner {
    if (spinCount) {
        if (--spinCount == 0) {
            [self.progress stopAnimation:self];
        }
    }
}
- (NSOperationQueue *)copyQueue {
    if(queue == NULL) {
		queue = [NSOperationQueue new];
//		[queue setMaxConcurrentOperationCount:10];
		[queue setMaxConcurrentOperationCount:3];
	}
	return queue;
}

// execute block on queue; pauses updates & starts progress before; restore updates & stops progress on completion
- (void)runBlockOnQueue:(void (^)(void))block {
	[self.delegate treeViewController:self pauseRefresh:YES];
	[self startSpinner];
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:block];
	[op setCompletionBlock:^{
		[self stopSpinner];
		[self.delegate treeViewController:self pauseRefresh:NO];
	}];
	[[self copyQueue] addOperation:op];
}

- (BOOL)checkExistingTarget:(NSString *)target fileManager:(NSFileManager *)fileManager sourceDate:(NSDate *)sourceDate replace:(BOOL)replace createDirectories:(BOOL)create {
    cancelAll = NO;
	NSError *error = nil;
	if([fileManager fileExistsAtPath:target]) {
		if(replace) {
            return removeTarget(target, fileManager);
		}
		NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:target error:&error];
		NSComparisonResult dateDiff = [sourceDate compare:[fileAttributes fileModificationDate]];
		NSString *prompt = [NSString stringWithFormat:@"An %@item \"%@\" already exists.", (dateDiff == NSOrderedSame) ? @"" : (dateDiff == NSOrderedDescending) ? @"Older " : @"Newer ", [target lastPathComponent]];

		NSAlert *exists = [NSAlert new];
		[exists setMessageText:prompt];
		[exists setInformativeText:@"Do you want to replace it?"];
		[exists setAlertStyle:NSWarningAlertStyle];
		[exists addButtonWithTitle:@"Replace"];
		[exists addButtonWithTitle:@"Skip"];
		[exists addButtonWithTitle:@"Cancel"];
		NSInteger result = [exists runModal];
		if(result == NSAlertFirstButtonReturn) {
            return removeTarget(target, fileManager);
		}
		if(result == NSAlertThirdButtonReturn) {
            cancelAll = YES;
		}
		return NO;
	}
    NSString *targetDir = [target stringByDeletingLastPathComponent];
	if(![fileManager fileExistsAtPath:targetDir]) {
		if(create) {
            return createTargetDir(targetDir, fileManager);
		}
		NSString *prompt = [NSString stringWithFormat:@"Directory %@ does not exist.", targetDir ];
		NSAlert *exists = [NSAlert new];
		[exists setMessageText:prompt];
		[exists setInformativeText:@"Do you want to create it?"];
		[exists setAlertStyle:NSWarningAlertStyle];
		[exists addButtonWithTitle:@"OK"];
		[exists addButtonWithTitle:@"Cancel"];
		NSInteger result = [exists runModal];
		if(result == NSAlertFirstButtonReturn) {
            return createTargetDir(targetDir, fileManager);
		}
		return NO;
	}
	return YES;
}
- (NSArray *)dirsInTabs {
	NSArray *tvcArray = [self.delegate tvcInTabs];
	NSMutableArray *dest = [NSMutableArray arrayWithCapacity:[tvcArray count]];
	for(TreeViewController *tvc in tvcArray) {
		[dest addObject:[[tvc selectedDir] fullPath]];
	}
	return dest;
}
/*! @brief This method sets target directories in NSComboBox to directories in tabs
 */
- (void)initPanelDest:(id)panel {
	NSArray *dest = [self dirsInTabs];
	NSInteger n = [self.delegate currentTab];
	if (n < [dest count] -1 )
		n++;
	else if (n) n--;
	NSUInteger destItem = [dest indexOfObject:targetDirectory];
	if (destItem != NSNotFound)	// previous target
		n = destItem;
	[panel setTargetDirs:dest];
	[panel setSelectedTarget:n];
}
- (void)initCopyPanel:(FileSystemItem *)node {
	copyPanel = [CopyPanelController new];
	[copyPanel setFrom:node.fullPath];
	[copyPanel setFilename:node.relativePath];
	[self initPanelDest:copyPanel];
}
- (void)initTaggedCopyPanel:(NSArray *)objects {
	copyPanel = [CopyPanelController new];
	[copyPanel setFrom:[NSString stringWithFormat:@"%ld tagged Files", [objects count]]];
	[copyPanel setFilename:@"*.*"];
	[self initPanelDest:copyPanel];
}
- (void)initTaggedBatchPanel:(NSArray *)objects {
	batchPanel = [BatchPanelController new];
	[self initPanelDest:batchPanel];
}

#pragma mark - Operations to execute after completion of queue
- (void)refreshTargetDirNP:(DirectoryItem *)dir { // completion of paste
    if (dir) {
        if ([dir isPathLoaded]) {
            [dir updateDirectory];	// Update target directory if loaded.
        }
    }
}
- (void)symlinkTo:(FileSystemItem *)node {
	[self initCopyPanel:node];
	[copyPanel setTitle:@"Create Symlink"];
	if ([copyPanel runModal] == NSOKButton) {
		NSFileManager *fileManager = [NSFileManager new];
		targetDirectory = copyPanel.targetDirectory;
		NSString *target = [targetDirectory stringByAppendingPathComponent:[node.relativePath stringByRenamingingLastPathComponent:copyPanel.filename]];
		if([self checkExistingTarget:target fileManager:fileManager sourceDate:[node wDate] replace:[copyPanel.replaceExisting state] createDirectories:[copyPanel.createDirectories state]]) {
			NSError *error = nil;
			[self.delegate treeViewController:self pauseRefresh:YES];
            if([fileManager createSymbolicLinkAtPath:target
								 withDestinationPath:node.fullPath
											   error:&error]) {
				[self refreshTargetDirNP:findPathInVolumes(copyPanel.targetDirectory)];
				[self.delegate treeViewController:self pauseRefresh:NO];
            } else {
				[self.delegate treeViewController:self pauseRefresh:NO];
                if (error) {
					NSAlert *alert = [NSAlert alertWithError:error];
					[alert runModal];
                }
            }
		}
	}
    copyPanel = nil;
}
#pragma mark -

// This method does the actual File/Directory copying
// NSFileManager performs the physical copy on the file system
// The target directory is then updated to show the new contents
- (void)copyObjects:(NSArray *)objectsToCopy targetDirectory:(NSString *)copyTargetDirectory copiedFilename:(NSString *)copiedFilename createDirectories:(BOOL)createDirectories replaceExisting:(BOOL)replaceExisting {
	NSFileManager *fileManager = [NSFileManager new];
	// First check for Existing Target (needs to run on main thread for Alert)
	NSMutableArray *newobjectsToCopy = [NSMutableArray arrayWithCapacity:[objectsToCopy count]];
	for (FileItem *node in objectsToCopy) {
		NSString *target = [copyTargetDirectory stringByAppendingPathComponent:[node.relativePath stringByRenamingingLastPathComponent:copiedFilename]];
		if([self checkExistingTarget:target fileManager:fileManager sourceDate:[node wDate] replace:replaceExisting createDirectories:createDirectories]) {
			[newobjectsToCopy addObject:node];
		}
		if(cancelAll)   break;
	}
	if([newobjectsToCopy count] == 0)   return;
	[self runBlockOnQueue:^{
		for (FileItem *node in newobjectsToCopy) {
			NSError *error = nil;
			NSString *target = [copyTargetDirectory stringByAppendingPathComponent:[node.relativePath stringByRenamingingLastPathComponent:copiedFilename]];
			if(![fileManager copyItemAtPath:node.fullPath
									 toPath:target
									  error:&error]) {
				if (error) {
					[[NSOperationQueue mainQueue] addOperationWithBlock:^{
						NSAlert *alert = [NSAlert alertWithError:error];
						[alert runModal];
					}];
				}
			}
		}
		[self refreshTargetDirNP:findPathInVolumes(copyTargetDirectory)];    // refresh target after completion of copy
	}];
}

// This method does the actual File/Directory moving
// NSFileManager performs the physical move on the file system
// FileSystemItems are moved to their new locations
// The display is updated - either by NSArrayController (for files) or reloading tree (for directories)
- (void)moveObjects:(NSArray *)objectsToMove targetDirectory:(NSString *)moveTargetDirectory movedFilename:(NSString *)movedFilename createDirectories:(BOOL)createDirectories replaceExisting:(BOOL)replaceExisting {
	NSFileManager *fileManager = [NSFileManager new];
	// First check for Existing Target (needs to run on main thread for Alert)
	NSMutableArray *newobjectsToMove = [NSMutableArray arrayWithCapacity:[objectsToMove count]];
	for (FileItem *node in objectsToMove) {
		NSString *target = [moveTargetDirectory stringByAppendingPathComponent:[node.relativePath stringByRenamingingLastPathComponent:movedFilename]];
		if([self checkExistingTarget:target fileManager:fileManager sourceDate:[node wDate] replace:replaceExisting createDirectories:createDirectories]) {
			[newobjectsToMove addObject:node];
		}
		if(cancelAll)   break;
	}
	if([newobjectsToMove count] == 0)   return;
	[self runBlockOnQueue:^{
		for (FileItem *node in newobjectsToMove) {
			NSString *target = [moveTargetDirectory stringByAppendingPathComponent:[node.relativePath stringByRenamingingLastPathComponent:movedFilename]];
			NSString *itemToRemove = [node fullPath];	// item to delete
			DirectoryItem *oldParent = [node parent];   // need to capture before move
			NSError *error = nil;
			if([fileManager moveItemAtPath:node.fullPath
									toPath:target
									 error:&error]) {	// physical move on the file system
				DirectoryItem *targetDir = findPathInVolumes(moveTargetDirectory);
				if (targetDir) {
					if ([targetDir isPathLoaded]) {	// FileSystemItems are renamed and moved to their new locations
						node.relativePath = [target lastPathComponent];
						[targetDir moveItem:node];	// move node to targetDir
					}
				}
				if ([node isKindOfClass:[FileItem class]]) {	// The display is updated
					NSMutableArray *files = [oldParent files];
					if (inBranch) {
						[self.filesInDir removeObject:node];    // remove from Branch Array
					}
					[files removeObject:node];    // remove from Parent
				} else {
					[oldParent removeDir:(DirectoryItem *)node];
					[self.delegate treeViewController:self didRemoveDirectory:itemToRemove];
					[self.dirTree reloadData];
					[self updateSelectedDir];	// force update after move
				}
			}
			else {
				if (error) {
					[[NSOperationQueue mainQueue] addOperationWithBlock:^{
						NSAlert *alert = [NSAlert alertWithError:error];
						[alert runModal];
					}];
				}
			}
		}
	}];
}

- (void)moveTaggedTo:(NSArray *)objectsToMove {
	[self initTaggedCopyPanel:objectsToMove];
	[copyPanel setTitle:@"Move Tagged Files"];
	if ([copyPanel runModal] == NSOKButton) {
		[self moveObjects:objectsToMove  targetDirectory:copyPanel.targetDirectory movedFilename:copyPanel.filename createDirectories:[copyPanel.createDirectories state] replaceExisting:[copyPanel.replaceExisting state]];
	}
	copyPanel = nil;
}
- (void)moveTo:(FileSystemItem *)node {
	[self initCopyPanel:node];
	if ([node isKindOfClass:[FileItem class]])
		[copyPanel setTitle:@"Move File"];
	else
		[copyPanel setTitle:@"Move Directory"];
	if ([copyPanel runModal] == NSOKButton) {
		[self moveObjects:[NSArray arrayWithObject:node] targetDirectory:copyPanel.targetDirectory movedFilename:copyPanel.filename createDirectories:[copyPanel.createDirectories state] replaceExisting:[copyPanel.replaceExisting state]];
	}
    copyPanel = nil;
}
- (void)copyTaggedTo:(NSArray *)objectsToCopy {
	[self initTaggedCopyPanel:objectsToCopy];
	[copyPanel setTitle:@"Copy Tagged Files"];
	if ([copyPanel runModal] == NSOKButton) {
		[self copyObjects:objectsToCopy  targetDirectory:copyPanel.targetDirectory copiedFilename:copyPanel.filename createDirectories:[copyPanel.createDirectories state] replaceExisting:[copyPanel.replaceExisting state]];
	}
    copyPanel = nil;
}
- (void)copyTo:(FileSystemItem *)node {
	[self initCopyPanel:node];
	if ([node isKindOfClass:[FileItem class]])
		[copyPanel setTitle:@"Copy File"];
	else
		[copyPanel setTitle:@"Copy Directory"];
	if ([copyPanel runModal] == NSOKButton) {
		[self copyObjects:[NSArray arrayWithObject:node]  targetDirectory:copyPanel.targetDirectory copiedFilename:copyPanel.filename createDirectories:[copyPanel.createDirectories state] replaceExisting:[copyPanel.replaceExisting state]];
	}
    copyPanel = nil;
}
//%1 - the file's path and name
//%2 - the file's volume *
//%3 - the file's last path component (name + extension) *
//%4 - the file's name
//%5 - the file's extension
- (void)batchForTagged:(NSArray *)objectsForBatch {
	[self initTaggedBatchPanel:objectsForBatch];
	if ([batchPanel runModal] == NSOKButton) {
		NSFileManager *fileManager = [NSFileManager new];
		const char *filename = [fileManager fileSystemRepresentationWithPath:[batchPanel.targetDirectory stringByAppendingPathComponent:batchPanel.batchFileName.stringValue]];
		FILE *fp = fopen(filename, "w");

		NSString *batchArgs =  batchPanel.batchArgs.stringValue;
		for (FileItem *node in objectsForBatch) {
			NSString *path = node.fullPath;
			NSString *volume = volumeForPath(path);
			if(volume.length > 1) volume = [volume stringByAppendingString:@"/"];	// Ensure Volume ends in /
			NSString *relativePath = node.relativePath;
			NSString *filename = [relativePath stringByDeletingPathExtension];
			NSString *ext = relativePath.pathExtension;
			NSString *batchCmd = batchArgs;
			batchCmd = [batchCmd stringByReplacingOccurrencesOfString:@"%1" withString:path];
			batchCmd = [batchCmd stringByReplacingOccurrencesOfString:@"%2" withString:volume];
			batchCmd = [batchCmd stringByReplacingOccurrencesOfString:@"%3" withString:relativePath];
			batchCmd = [batchCmd stringByReplacingOccurrencesOfString:@"%4" withString:filename];
			batchCmd = [batchCmd stringByReplacingOccurrencesOfString:@"%5" withString:ext];
			fprintf(fp, "%s\n", batchCmd.UTF8String);
//			fprintf(fp, "%s,\t%s,\t%s,\t%s,\t%s\n", path.fileSystemRepresentation, volume.UTF8String, relativePath. UTF8String, filename.UTF8String, ext.UTF8String);
		}
		fclose(fp);
		chmod(filename, 0774);
	}
	 batchPanel = nil;
}
- (void)pasteTo:(DirectoryItem *)targetDir {
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	NSArray *classes = [NSArray arrayWithObject:[NSURL class]];
	NSDictionary *options = [NSDictionary dictionaryWithObject:
							 [NSNumber numberWithBool:YES] forKey:NSPasteboardURLReadingFileURLsOnlyKey];
	NSArray *fileURLs = [pasteboard readObjectsForClasses:classes options:options];
	// First check for Existing Target (needs to run on main thread for Alert)
	NSMutableArray *newFileURLs = [NSMutableArray arrayWithCapacity:[fileURLs count]];
	NSFileManager *fileManager = [NSFileManager new];
	NSURL *toUrl = [targetDir url];
	NSDate *tempDate;
	for(NSURL *url in fileURLs) {
		[url getResourceValue:&tempDate forKey:NSURLContentModificationDateKey error:nil];
		NSString *target = [[toUrl URLByAppendingPathComponent:[url lastPathComponent]] path];
		if([self checkExistingTarget:target fileManager:fileManager sourceDate:tempDate replace:NO createDirectories:NO]) {
			[newFileURLs addObject:url];
		}
		if(cancelAll)   break;
	}

	[self runBlockOnQueue:^{
		for(NSURL *url in newFileURLs) {
			NSError *error = nil;
			if(![fileManager copyItemAtURL:url
									 toURL:[toUrl URLByAppendingPathComponent:[url lastPathComponent]]
									 error:&error]) {
				if (error) {
					[[NSOperationQueue mainQueue] addOperationWithBlock:^{
						NSAlert *alert = [NSAlert alertWithError:error];
						[alert runModal];
					}];
				}
			}
		}
		[self refreshTargetDirNP:targetDir];    // refresh target after completion of paste
	}];
}

- (void)renameSingle:(FileSystemItem *)node  {
	NSFileManager *fileManager = [NSFileManager new];
	NSError *error = nil;
	NSString *target = [[node.fullPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:[node.relativePath stringByRenamingingLastPathComponent:renamePanel.filename]];
	NSString *newName = [target lastPathComponent];
	if([fileManager moveItemAtPath:node.fullPath
							toPath:target
							 error:&error]) {
		node.relativePath = newName;
		[self reloadData];
	}
	else if (error) {
		if([fileManager fileExistsAtPath:target]) {
			NSString *prompt = [NSString stringWithFormat:@"%@ already exists.", newName];
			NSAlert *exists = [NSAlert new];
			[exists setMessageText:prompt];
			[exists setAlertStyle:NSWarningAlertStyle];
			[exists addButtonWithTitle:@"OK"];
			[exists runModal];
		}
		else {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
		}
	}
}
- (void)renameTaggedTo:(NSArray *)objects {
    renamePanel = [RenamePanelController new];
	[renamePanel setTitle:@"Rename Tagged Files"];
	[renamePanel setFrom:[NSString stringWithFormat:@"%ld tagged Files", [objects count]]];
	[renamePanel setFilename:self.renameMask];
	if ([renamePanel runModal] == NSOKButton) {
		[self setRenameMask:[renamePanel filename]];	// Update saved mask
		[self.delegate treeViewController:self pauseRefresh:YES];
		for (FileItem *node in objects) {
			[self renameSingle:node];
		}
		[self.delegate treeViewController:self pauseRefresh:NO];
	}
    renamePanel = nil;
}
- (void)renameTo:(FileSystemItem *)node {
    renamePanel = [RenamePanelController new];
	[renamePanel setFrom:node.relativePath];
	[renamePanel setFilename:node.relativePath];
	if ([node isKindOfClass:[FileItem class]])
		[renamePanel setTitle:@"Rename File"];
	else
		[renamePanel setTitle:@"Rename Directory"];
	if ([renamePanel runModal] == NSOKButton) {
		[self.delegate treeViewController:self pauseRefresh:YES];
		[self renameSingle: node];
		[self.delegate treeViewController:self pauseRefresh:NO];
	}
    renamePanel = nil;
}

@end
