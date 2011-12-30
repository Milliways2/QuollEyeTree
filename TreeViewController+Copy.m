//
//  TreeViewController+Copy.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 20/12/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "TreeViewController+Copy.h"
#import "MyWindowController.h"
#import "DirectoryItem.h"
#import "volume.h"
#import "FileItem.h"
#import "CopyPanelController.h"
#import "RenamePanelController.h"
#import "NSString+Rename.h"

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

void removeItemForPath(NSString *path) {
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
BOOL removeTarget(NSString *target, NSFileManager *fileManager) {
	NSError *error = nil;
    if([fileManager removeItemAtPath:target error:&error]) {
        removeItemForPath(target);
        return YES;
    }
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
    return NO;
}
BOOL createTargetDir(NSString *targetDir, NSFileManager *fileManager) {
	NSError *error = nil;
    if([fileManager createDirectoryAtPath:targetDir withIntermediateDirectories:YES attributes:nil error:&error]) {
        return YES;
    }
    NSAlert *alert = [NSAlert alertWithError:error];
    [alert runModal];
    return NO;
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
- (void)initCopyDest {
	NSArray * dest = [self dirsInTabs];
	NSInteger n = [self.delegate currentTab];
	if (n < [dest count] -1 )
		n++;
	else if (n) n--;
	[copyPanel setTargetDirs:dest];
	[copyPanel setSelectedDir:n];
}
- (void)initCopyPanel:(FileSystemItem *)node {
	copyPanel = [CopyPanelController new];
	[copyPanel setFrom:node.fullPath];
	[copyPanel setFilename:node.relativePath];
	[self initCopyDest];
}
- (void)initTaggedCopyPanel:(NSArray *)objects {
	copyPanel = [CopyPanelController new];
	[copyPanel setFrom:[NSString stringWithFormat:@"%ld tagged Files", [objects count]]];
	[copyPanel setFilename:@"*.*"];
	[self initCopyDest];
}

#pragma mark - Operations to execute after completion of queue
- (void)refreshTargetDirectory:(NSString *)targetDir {  // completion of copy
    DirectoryItem *dir = findPathInVolumes(targetDir);
    if (dir) {
        if ([dir isPathLoaded]) {
            [dir updateDirectory];	// Update target directory if loaded.
        }
    }
    [self.delegate treeViewController:self pauseRefresh:NO];
    [self stopSpinner];
}
- (void)refreshTargetDir:(DirectoryItem *)dir { // completion of paste
    [dir updateDirectory];	// Update target directory.
    [self.delegate treeViewController:self pauseRefresh:NO];
    [self stopSpinner];
}
- (void)restoreRefresh:(id)arg {    // completion of move
    [self.delegate treeViewController:self pauseRefresh:NO];
    [self stopSpinner];
}
// add operation to execute after completion as last operation in queue
- (void)refreshAfter:(SEL)completionOperation object:(id)arg {
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithTarget:self
                                                                     selector:completionOperation
                                                                       object:arg];
    if ([[queue operations] count]) {
        for (NSOperation *copyOp in [queue operations]) {
            [op addDependency:copyOp];
        }
        [queue addOperation:op];
        return;
    }
    [self.delegate treeViewController:self pauseRefresh:NO];
    [self stopSpinner];
}
#pragma mark -
- (void)copySingle:(FileSystemItem *)node {
	NSFileManager *fileManager = [NSFileManager new];
	NSString *target = [copyPanel.targetDirectory stringByAppendingPathComponent:[node.relativePath stringByRenamingingLastPathComponent:copyPanel.filename]];
	if([self checkExistingTarget:target fileManager:fileManager sourceDate:[node wDate] replace:[copyPanel.replaceExisting state] createDirectories:[copyPanel.createDirectories state]]) {
        if(queue == NULL) {
            queue = [NSOperationQueue new];
            [queue setMaxConcurrentOperationCount:10];
        }

        [queue addOperationWithBlock:^{
            NSError *error = nil;
            [self startSpinner];
            if([fileManager copyItemAtPath:node.fullPath
                                    toPath:target 
                                     error:&error]) {
                [self stopSpinner];
            }
            else {
                [self stopSpinner];
                if (error) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        NSAlert *alert = [NSAlert alertWithError:error];
                        [alert runModal];
                    }];
                }
            }
        }];

	}
}
- (void)moveSingle:(FileSystemItem *)node  {
	NSFileManager *fileManager = [NSFileManager new];
	NSString *targetDirectory = copyPanel.targetDirectory;    // save for update after move
	NSString *target = [targetDirectory stringByAppendingPathComponent:[node.relativePath stringByRenamingingLastPathComponent:copyPanel.filename]];
	NSString *itemToRemove = [node fullPath];	// item to delete
	NSString *newName = [target lastPathComponent];
	if([self checkExistingTarget:target fileManager:fileManager sourceDate:[node wDate] replace:[copyPanel.replaceExisting state] createDirectories:[copyPanel.createDirectories state]]) {
        if(queue == NULL) {
            queue = [NSOperationQueue new];
            [queue setMaxConcurrentOperationCount:10];
        }

        DirectoryItem *targetDir = findPathInVolumes(targetDirectory);
        [queue addOperationWithBlock:^{
            NSError *error = nil;
            [self startSpinner];
            DirectoryItem *oldParent = [node parent];   // need to capture before move
            if([fileManager moveItemAtPath:node.fullPath
                                    toPath:target
                                     error:&error]) {
                [self stopSpinner];
                // Update display on Main Queue after physical move
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//                    DirectoryItem *oldParent = [node parent];
                    if (targetDir) {
                        if ([targetDir isPathLoaded]) {
                            node.relativePath = newName;
                            [targetDir moveItem:node];
                        }
                    }
                    if ([node isKindOfClass:[FileItem class]]) {
                        NSMutableArray *files = [oldParent files];
                        if (inBranch) {
                            [self.filesInDir removeObject:node];    // remove from Branch Array
                        }
                        [files removeObject:node];    // remove from Parent
                    } else {
                        [oldParent removeDir:(DirectoryItem *)node];
                        [self.delegate treeViewController:self didRemoveDirectory:itemToRemove];
                        [self.dirTree reloadData];
                    }
                }];
            }
            else {
                [self stopSpinner];
                if (error) {
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        NSAlert *alert = [NSAlert alertWithError:error];
                        [alert runModal];
                    }];
                }
            }
        }];
        
	}
}

- (void)copyTaggedTo:(NSArray *)objectsToCopy {
	[self initTaggedCopyPanel:objectsToCopy];
	[copyPanel setTitle:@"Copy Tagged Files"];
	if ([copyPanel runModal] == NSOKButton) {
		[self.delegate treeViewController:self pauseRefresh:YES];
		for (FileItem *node in objectsToCopy) {
            [self copySingle:node];
            if(cancelAll)   break;
		}
        [self refreshAfter:@selector(refreshTargetDirectory:) object:copyPanel.targetDirectory];    // refresh target after completion of copy
	}
    copyPanel = nil;
}
- (void)moveTaggedTo:(NSArray *)objectsToCopy {
	[self initTaggedCopyPanel:objectsToCopy];
	[copyPanel setTitle:@"Move Tagged Files"];
	if ([copyPanel runModal] == NSOKButton) {
		[self.delegate treeViewController:self pauseRefresh:YES];
		for (FileItem *node in objectsToCopy) {
			[self moveSingle:node];
            if(cancelAll)   break;
		}
        [self refreshAfter:@selector(restoreRefresh:) object:nil];    // refresh target after completion of move
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
		[self.delegate treeViewController:self pauseRefresh:YES];
		[self copySingle:node];
        [self refreshAfter:@selector(refreshTargetDirectory:) object:copyPanel.targetDirectory];    // refresh target after completion of copy
	}
    copyPanel = nil;
}
- (void)moveTo:(FileSystemItem *)node {
	[self initCopyPanel:node];
	if ([node isKindOfClass:[FileItem class]])
		[copyPanel setTitle:@"Move File"];
	else {
		[copyPanel setTitle:@"Move Directory"];
	}
	if ([copyPanel runModal] == NSOKButton) {
		[self.delegate treeViewController:self pauseRefresh:YES];
		[self moveSingle:node];
        [self refreshAfter:@selector(restoreRefresh:) object:nil];    // refresh target after completion of move
	}
    copyPanel = nil;
}

- (void)pasteTo:(DirectoryItem *)targetDir {
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	NSArray *classes = [NSArray arrayWithObject:[NSURL class]];
	NSDictionary *options = [NSDictionary dictionaryWithObject:
							 [NSNumber numberWithBool:YES] forKey:NSPasteboardURLReadingFileURLsOnlyKey];
	NSArray *fileURLs = [pasteboard readObjectsForClasses:classes options:options];
	NSURL *toUrl = [targetDir url];
	
	[self.delegate treeViewController:self pauseRefresh:YES];
	NSFileManager *fileManager = [NSFileManager new];
	NSDate *tempDate;
	NSString *target;
	for(NSURL *url in fileURLs) {
		[url getResourceValue:&tempDate forKey:NSURLContentModificationDateKey error:nil];
		target = [[toUrl URLByAppendingPathComponent:[url lastPathComponent]] path];
		if([self checkExistingTarget:target fileManager:fileManager sourceDate:tempDate replace:NO createDirectories:NO]) {
            if(queue == NULL) {
                queue = [NSOperationQueue new];
                [queue setMaxConcurrentOperationCount:10];
            }

            [queue addOperationWithBlock:^{
                NSError *error = nil;
                [self startSpinner];
                if([fileManager copyItemAtURL:url
                                        toURL:[toUrl URLByAppendingPathComponent:[url lastPathComponent]]
                                        error:&error]) {
                    [self stopSpinner];
                }
                else {
                    [self stopSpinner];
                    if (error) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            NSAlert *alert = [NSAlert alertWithError:error];
                            [alert runModal];
                        }];
                    }
                }
            }];  

		}
        if(cancelAll)   break;
	}
    [self refreshAfter:@selector(refreshTargetDir:) object:targetDir];    // refresh target after completion of paste
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
	[renamePanel setFilename:@"*.*"];		
	if ([renamePanel runModal] == NSOKButton) {
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
