//
//  TreeViewController+Dirs.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 2/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "TreeViewController+Dirs.h"
#import "MyWindowController.h"
#import "DirectoryItem.h"
#import "FileItem.h"
#import "volume.h"
#import "ImageAndTextCell.h"
#import "FolderPanelController.h"
#import "ComparePanelController.h"
#import "DeletedItems.h"

@interface TreeViewController()
//  TreeViewController
- (void)setDirMenu;
- (void)enterFileView;
- (FileItem *)fileSelected;
- (BOOL)areFilesVisible;
- (void)applyFileAndTagFilter:(NSPredicate *)filePredicate;
- (void)copyToPasteboard:(id)object;
- (void)toggleTopSubView:(id)sender;
//  TreeViewController+Copy
- (void)startSpinner;
- (void)stopSpinner;
- (NSArray *)dirsInTabs;
- (void)copyTo:(FileSystemItem *)node;
- (void)moveTo:(FileSystemItem *)node;
- (void)renameTo:(FileSystemItem *)node;
- (void)pasteTo:(DirectoryItem *)node;
@end

@implementation TreeViewController(Dirs)
- (void)dClickDirectory:(NSArray*)selectedObjects {
	[self setTreeRootNode:(DirectoryItem *)[self.dirTree itemAtRow:[self.dirTree selectedRow]]];
}
- (void)updateSelectedDir {
	if ([self.dirTree selectedRow] < 0 ) return;
	DirectoryItem *selDir = [self.dirTree itemAtRow:[self.dirTree selectedRow]];	// Previous Directory may no longer exist!
	if (selDir != self.selectedDir) {
		self.selectedDir = selDir;
		self.filesInDir = self.selectedDir.files;
        self.currDir = self.selectedDir.url;    // refresh NSPathControl *currentPath
		inBranch = NO;  // can't be inBranch if selection change
	}
}

#pragma mark - Dir Menu Actions
- (void)showAllFiles:(BOOL)inRoot tagged:(BOOL)tagged {
    if(tagged && !showOnlyTagged)   [self toggleShowTagged];
    inBranch = YES;
    [self startSpinner];
	self.filesInDir = [inRoot ? [self.selectedDir rootDir] : self.selectedDir filesInBranch];
    [self stopSpinner];
    [self.fileList setBackgroundColor:[NSColor selectedControlColor]];
	[self toggleTopSubView:self];
    [self enterFileView];
}
- (void)copyDirTo {
	[self copyTo:self.selectedDir];
}
- (void)moveDirTo {
	[self moveTo:self.selectedDir];
    [self updateSelectedDir];
}
- (void)pasteURL {
    [self pasteTo:self.selectedDir];
}
- (void)compareDir {
	DirectoryItem *node = self.selectedDir;
    ComparePanelController *comparePanel = [ComparePanelController singleton];
	[comparePanel setFrom:node.fullPath];
	[comparePanel setTargetDirs:[self dirsInTabs]];

	NSInteger n = [self.delegate currentTab] + 1;
	[comparePanel setSelectedDir:n];
	if ([comparePanel runModal] == NSOKButton) {
		NSArray *currentContents = [[self.selectedDir files] filteredArrayUsingPredicate:fileFilterPredicate];
		DirectoryItem *targetDir = findPathInVolumes(comparePanel.targetDirectory);
		if (targetDir) {
			if (![targetDir isPathLoaded]) {
                comparePanel = nil;
				return;
			}
		}
		NSArray *targetFiles = 	[targetDir files];
		
		for (FileItem *node in currentContents) {
			NSString *fileName = node.relativePath;
			BOOL itemFound = NO;
			for (FileItem *element in targetFiles) {
				if ([[element relativePath] compare:fileName options:NSCaseInsensitiveSearch] == NSOrderedSame) {
					itemFound = YES;
					NSTimeInterval timeDiff = [node.wDate timeIntervalSinceDate:element.wDate];
					NSInteger sizeDiff = [node.fileSize integerValue] - [element.fileSize integerValue];
					if (timeDiff < 0)		{ if ([comparePanel.dateOlder state])	node.tag = YES;}
					else if (timeDiff > 0)	{ if ([comparePanel.dateNewer state])	node.tag = YES;}
					else {
						if ([comparePanel.dateSame state])	node.tag = YES;
						else if ((sizeDiff == 0) && [comparePanel.compareIdentical state])	node.tag = YES;
					}
					if (sizeDiff < 0)		{ if ([comparePanel.sizeSmaller state])	node.tag = YES;}
					else if (sizeDiff > 0)	{ if ([comparePanel.sizeLarger state])	node.tag = YES;}
					else if ([comparePanel.sizeEqual state])	node.tag = YES;
					break;
				}
			}
			if(!itemFound) { if ([comparePanel.compareUnique state])	node.tag = YES;}
		}
	}
    comparePanel = nil;
}
- (void)makeDir {
	FolderPanelController *folderPanel = [FolderPanelController new];
	[folderPanel setFrom:self.selectedDir.relativePath];
	[folderPanel setFilename:@"New Folder"];
	
	if ([folderPanel runModal] == NSOKButton) {
		[self.delegate treeViewController:self pauseRefresh:YES];
		NSError *error = nil;
		NSString *newName = [folderPanel filename];
		NSString *target = [[self.selectedDir fullPath] stringByAppendingPathComponent:newName];
		NSFileManager *fileManager = [NSFileManager new];
		if([fileManager createDirectoryAtPath:target withIntermediateDirectories:NO attributes:nil error:&error]) {
			[self.selectedDir updateDirectory];	// refresh directory
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
		[self.delegate treeViewController:self pauseRefresh:NO];
	}
}
- (void)renameDir {
	[self renameTo:self.selectedDir];
    [self updateSelectedDir];
}
- (void)toggleDir:(BOOL)all {
	[self.selectedDir toggleHidden:all];
    [self.selectedDir updateDirectory];
    [self reloadData];
}
- (void)moveDirToTrash {
	[self.delegate treeViewController:self pauseRefresh:YES];
	NSString *dirToRemove = [self.selectedDir fullPath];	// item to delete
	NSArray *dirsToDelete = [NSArray arrayWithObject:self.selectedDir.url];
	[[NSWorkspace sharedWorkspace] recycleURLs:dirsToDelete
							 completionHandler:^(NSDictionary *newURLs, NSError *error) {
								 if (error == nil) {
                                     [[DeletedItems sharedDeletedItems] addWithPath:dirToRemove trashLocation:[[newURLs objectForKey:self.selectedDir.url] path]];
									 [self.selectedDir removeSelf];
									 [self.dirTree reloadData];
                                     [self updateSelectedDir];
									 [self.delegate treeViewController:self didRemoveDirectory:dirToRemove];
								 }
								 else {
									 NSAlert *alert = [NSAlert alertWithError:error];
									 [alert runModal];
								 }
								 [self.delegate treeViewController:self pauseRefresh:NO];
							 } ];
}

#pragma mark Delegate Actions
- (BOOL)keyPressedInOutlineView:(unichar)character {
	if (character == NSF3FunctionKey) {
		[self.selectedDir updateDirectory];
		[self reloadData];
		return YES;
	}
	if (character == 0x0d) {
		[self enterFileView];
		return YES;
	}
	if (character == '*') {
		[self.dirTree expandItem:self.selectedDir expandChildren:YES];
		return YES;
	}
	if (character == '+' || character == '=') {
		[self.dirTree expandItem:self.selectedDir];
		return YES;
	}
	if (character == '-') {
        [self.dirTree collapseItem:self.selectedDir collapseChildren:YES];
	}
	if (character == NSF6FunctionKey) {
		if ([self.dirTree isItemExpanded:self.selectedDir])
            [self.dirTree collapseItem:self.selectedDir];
        else
            [self.dirTree expandItem:self.selectedDir];
		return YES;
	}
    if (character == NSF5FunctionKey) {
		if (![self.dirTree isItemExpanded:self.selectedDir]) {
            [self.dirTree expandItem:self.selectedDir];
            return YES;
        }
        BOOL expanded = NO;
        DirectoryItem *dir;
        for (dir in [self.selectedDir loggedSubDirectories])
            expanded = expanded || [self.dirTree isItemExpanded:dir];
        if (expanded)   // any subdirectory is expanded
            for (dir in [self.selectedDir loggedSubDirectories])
                [self.dirTree collapseItem:dir];
        else
            for (dir in [self.selectedDir loggedSubDirectories])
                [self.dirTree expandItem:dir];
        return YES;
    }
	return NO;
}
- (BOOL)keyCmdPressedInOutlineView:(unichar)character {
	if (character == NSUpArrowFunctionKey) {
		[self setTreeRootNode:(DirectoryItem *)[dataRoot parent]];
		return YES;
	}
	return NO;
}
- (BOOL)keyCtlPressedInOutlineView:(unichar)character {
	if (character == 0x0d) {
        [self toggleShowTagged];
		return YES;
	}
	if (character == 'b') {
        [self showAllFiles:NO tagged:YES];
		return YES;
	}
	if (character == 's') {
        [self showAllFiles:YES tagged:YES];
		return YES;
	}
	return NO;
}

- (void)mouseDownInOutlineView {
	if(inFileView) {
		[self setDirMenu];
	}
}

#pragma mark Context Menu Actions
- (IBAction)copyDir:(id)sender {
	self.selectedDir = [self.dirTree itemAtRow:[self.dirTree selectedRow]];	// save selected Dir for future actions
	[self copyToPasteboard:self.selectedDir.url];
}
- (IBAction)copyDirToClipboard:(id)sender {
	self.selectedDir = [self.dirTree itemAtRow:[self.dirTree selectedRow]];	// save selected Dir for future actions
	[self copyToPasteboard:self.selectedDir.fullPath];
}
- (IBAction)openDirectory:(id)sender {
	self.selectedDir = [self.dirTree itemAtRow:[self.dirTree selectedRow]];	// save selected Dir for future actions
	LSOpenCFURLRef((__bridge CFURLRef)self.selectedDir.url, nil);
}
- (IBAction)revealDirInFinder:(id)sender {
	self.selectedDir = [self.dirTree itemAtRow:[self.dirTree selectedRow]];	// save selected Dir for future actions
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:self.selectedDir.url]];
}
- (IBAction)openDirInNewTab:(id)sender {
	self.selectedDir = [self.dirTree itemAtRow:[self.dirTree selectedRow]];	// save selected Dir for future actions
	[self.delegate treeViewController:self addNewTabAtDir:self.selectedDir];
}
- (IBAction)addDirToSidebar:(id)sender {
	self.selectedDir = [self.dirTree itemAtRow:[self.dirTree selectedRow]];	// save selected Dir for future actions
	[self.delegate treeViewController:self addToSidebar:self.selectedDir.fullPath];
}
- (IBAction)openDirInTerminal:(id)sender {
	self.selectedDir = [self.dirTree itemAtRow:[self.dirTree selectedRow]];	// save selected Dir for future actions
	NSString *s = [NSString stringWithFormat:
				   @"tell application \"Terminal\" to do script \"cd \'%@\'\"", self.selectedDir.fullPath];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
	[as executeAndReturnError:nil];		
}
- (IBAction)getDirInfo:(id)sender {
	self.selectedDir = [self.dirTree itemAtRow:[self.dirTree selectedRow]];	// save selected Dir for future actions
	NSString *s = [NSString stringWithFormat:
				   @"tell application \"Finder\"\n"
                   "open information window of %@  POSIX file \"%@\"\n"
                   "activate information window\n"
                   "end tell", (self.selectedDir.isAlias || self.selectedDir.isPackage) ? @"file" : @"folder", self.selectedDir.fullPath];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
//	[as executeAndReturnError:nil];		
    NSDictionary *errorInfo;
	if(![as executeAndReturnError:&errorInfo])	
        NSLog(@"errorInfo %@", errorInfo);
}

#pragma mark - NSOutlineViewDelegate Protocol methods
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [self updateSelectedDir];
}
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {	 
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
		if ([cell isKindOfClass:[ImageAndTextCell class]]) {
			if(![item nodeIcon]) {
				[item setNodeIcon:[[NSWorkspace sharedWorkspace] iconForFile:[item fullPath]]];
			}
			[(ImageAndTextCell*)cell setImage:[item nodeIcon]];	// set the cell's image
		}
	}
}
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    return NO;
}
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldReorderColumn:(NSInteger)columnIndex toColumn:(NSInteger)newColumnIndex {
    if (columnIndex == 0)   return NO;
    if (newColumnIndex == 0)    return NO;
    return YES;
}

#pragma mark NSOutlineViewDataSource Protocol methods

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return (item == nil) ? 1 : [item numberOfSubDirs];	// nil has 1 child - dataRoot
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    return (item == nil) ? YES : ([item numberOfSubDirs] != 0);
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return (item == nil) ? dataRoot : [(DirectoryItem *)item directoryAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
   return (id)[item valueForKey:[tableColumn identifier]];
}

@end