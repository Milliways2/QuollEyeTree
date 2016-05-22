//
//  TreeViewController+Dirs.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 2/10/11.
//  Copyright 2011-2015 Ian Binnie. All rights reserved.
//

#import "TreeViewController+Dirs.h"
#import "MyWindowController.h"
#import "DirectoryItem+Branch.h"
#import "DirectoryItem.h"
#import "FileItem.h"
#import "volume.h"
#import "alias.h"
#import "ImageAndTextCell.h"
#import "FolderPanelController.h"
#import "ComparePanelController.h"
#import "DeletedItems.h"
extern NSImage *aliasBadge;

@interface TreeViewController()
- (void)setDirMenu;
- (void)enterFileView;
- (FileItem *)fileSelected;
- (BOOL)areFilesVisible;
- (void)copyToPasteboard:(id)object;
- (void)toggleTopSubView:(id)sender;
@end
@interface TreeViewController(Copy)
- (void)startSpinner;
- (void)stopSpinner;
- (void)runBlockOnQueue:(void (^)(void))block;
- (NSArray *)dirsInTabs;
- (void)copyTo:(FileSystemItem *)node;
- (void)moveTo:(FileSystemItem *)node;
- (void)renameTo:(FileSystemItem *)node;
- (void)pasteTo:(DirectoryItem *)node;
- (void)symlinkTo:(FileSystemItem *)node;
@end
@interface TreeViewController(Filter)
- (void) checkFilter;
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
	[self checkFilter];
}
- (void)updateBranchInQueue:(DirectoryItem *)branch  {
	[self runBlockOnQueue:^{
		[branch updateBranch];
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self reloadData];
		}];
	}];
}

#pragma mark - Dir Menu Actions
- (void)showAllFiles:(BOOL)inRoot tagged:(BOOL)tagged {
    if(tagged && !showOnlyTagged)   [self toggleShowTagged];
    [self startSpinner];
	self.filesInDir = [inRoot ? [self.selectedDir rootDir] : self.selectedDir filesInBranch];
    [self stopSpinner];
	if ([self areFilesVisible]) {
		inBranch = YES;
		[self.fileList setUsesAlternatingRowBackgroundColors:NO];
		[self.fileList setBackgroundColor:[NSColor selectedControlColor]];
		[self toggleTopSubView:self];
		[self enterFileView];
	}
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
- (void)unhideBranch {
	DirectoryItem *node = self.selectedDir;
	for (DirectoryItem *dir in node.directoriesInBranch) {
		[dir cloneHidden:node];
	}
	[self updateBranchInQueue:self.selectedDir];
}

void getAllMatching(DirectoryItem *source, DirectoryItem *target, NSMutableArray **accumulated) {
	NSArray *targetDir = target.loggedSubDirectories;
	for (DirectoryItem *dir in source.loggedSubDirectories) {
		NSString *fileName = dir.relativePath;
		NSUInteger i = [targetDir indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
			if ([[obj relativePath] compare:fileName options:NSCaseInsensitiveSearch] == NSOrderedSame) {
				*stop = YES;
				return YES;
			}
			return NO;
        }];
		if (i != NSNotFound ) {
			[*accumulated addObject:[NSDictionary dictionaryWithObjectsAndKeys:dir, @"source", [targetDir objectAtIndex:i], @"target", nil]];
			getAllMatching(dir, [targetDir objectAtIndex:i], accumulated);
		}
	}
}
- (void)compareDir {
	DirectoryItem *node = self.selectedDir;
    ComparePanelController *comparePanel = [ComparePanelController singleton];
	[comparePanel setFrom:node.fullPath];
	[comparePanel setTargetDirs:[self dirsInTabs]];

	NSInteger n = [self.delegate currentTab] + 1;
	[comparePanel setSelectedTarget:n];
	if ([comparePanel runModal] == NSOKButton) {
		DirectoryItem *targetDir = findPathInVolumes(comparePanel.targetDirectory);
		if (targetDir) {
			if (![targetDir isPathLoaded]) {
                comparePanel = nil;
				return;
			}
		}
		NSMutableArray *accumulated = [NSMutableArray arrayWithCapacity:50];
		[accumulated addObject:[NSDictionary dictionaryWithObjectsAndKeys:node, @"source", targetDir, @"target", nil]];
		if ([comparePanel.compareMode selectedRow])
			getAllMatching (node, targetDir, &accumulated);	// if Directory get all matching subdirectories
		for (NSDictionary *dict in accumulated) {
			NSArray *currentContents = [[[dict objectForKey:@"source"] files] filteredArrayUsingPredicate:fileFilterPredicate];
			NSArray *targetFiles = 	[[dict objectForKey:@"target"] files];

			BOOL dateOlder = [comparePanel.dateOlder state];
			BOOL dateNewer = [comparePanel.dateNewer state];
			BOOL dateSame = [comparePanel.dateSame state];
			BOOL compareIdentical = [comparePanel.compareIdentical state];
			BOOL sizeSmaller = [comparePanel.sizeSmaller state];
			BOOL sizeLarger = [comparePanel.sizeLarger state];
			BOOL sizeEqual = [comparePanel.sizeEqual state];
			BOOL compareUnique = [comparePanel.compareUnique state];
			BOOL sameContent = [comparePanel.sameContent state];
			BOOL diffContent = [comparePanel.diffContent state];
			BOOL compareContent = sameContent || diffContent;
			NSString *fileName;
			for (FileItem *node in currentContents) {
				if (node.tag)	continue;	// already tagged
				fileName = node.relativePath;
				BOOL itemFound = NO;
				BOOL tag = NO;
				for (FileItem *element in targetFiles) {
					if ([[element relativePath] compare:fileName options:NSCaseInsensitiveSearch] == NSOrderedSame) {
						itemFound = YES;
						NSTimeInterval timeDiff = [node.wDate timeIntervalSinceDate:element.wDate];
						NSInteger sizeDiff = [node.fileSize integerValue] - [element.fileSize integerValue];

						if (timeDiff < 0)		{ if (dateOlder)	tag = YES;}
						else if (timeDiff > 0)	{ if (dateNewer)	tag = YES;}
						else {
							if (dateSame)	tag = YES;
							else if ((sizeDiff == 0) && compareIdentical)	tag = YES;
						}

						if (sizeDiff < 0)		{ if (sizeSmaller)	tag = YES;}
						else if (sizeDiff > 0)	{ if (sizeLarger)	tag = YES;}
						else if (sizeEqual)	tag = YES;

						if (tag && compareContent) {
							if (sizeDiff == 0) {
								tag = (sameContent == [[NSFileManager defaultManager] contentsEqualAtPath:[node fullPath] andPath:[element fullPath]]);	// i.e exclusive OR
							} else	tag = NO;
						}
						node.tag = tag;
						break;
					}
				}
				if(!itemFound) { if (compareUnique)	node.tag = YES;}
			}
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
	DirectoryItem *dir = self.selectedDir;
	NSString *dirToRemove = [dir fullPath];	// item to delete
	NSArray *dirsToDelete = [NSArray arrayWithObject:dir.url];
  	[[NSWorkspace sharedWorkspace] recycleURLs:dirsToDelete
							 completionHandler:^(NSDictionary *newURLs, NSError *error) {
								 if (error == nil) {
									 self.selectedDir = NULL;
                                     [[DeletedItems sharedDeletedItems] addWithPath:dirToRemove trashLocation:[[newURLs objectForKey:dir.url] path]];
									 [dir.parent removeDir:dir];
									 [self.dirTree reloadData];
									 [self updateSelectedDir];	// force update after move
									 [self.delegate treeViewController:self didRemoveDirectory:dirToRemove];
								 }
								 else {
									 NSAlert *alert = [NSAlert alertWithError:error];
									 [alert runModal];
								 }
								 [self.delegate treeViewController:self pauseRefresh:NO];
							 } ];
}

#pragma mark Context Menu Actions
- (IBAction)copyDir:(id)sender {	// context & menu
    DirectoryItem *item;
    if ([sender isKindOfClass:[MyWindowController class]])
		item = [self.dirTree itemAtRow:[self.dirTree selectedRow]];
	else
		item = (DirectoryItem *)[self.dirTree focusedItem];
	[self copyToPasteboard:item.url];
}
- (IBAction)copyDirToClipboard:(id)sender {	// context only
    DirectoryItem *item = (DirectoryItem *)[self.dirTree focusedItem];
	[self copyToPasteboard:item.fullPath];
}
- (IBAction)openDirectory:(id)sender {	// context & menu
    DirectoryItem *item;
    if ([sender isKindOfClass:[MyWindowController class]])
		item = [self.dirTree itemAtRow:[self.dirTree selectedRow]];
	else
		item = (DirectoryItem *)[self.dirTree focusedItem];
	LSOpenCFURLRef((__bridge CFURLRef)item.url, nil);
}
- (IBAction)revealDirInFinder:(id)sender {	// context & menu
    DirectoryItem *item;
    if ([sender isKindOfClass:[MyWindowController class]])
		item = [self.dirTree itemAtRow:[self.dirTree selectedRow]];
	else
		item = (DirectoryItem *)[self.dirTree focusedItem];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:item.url]];
}
- (IBAction)openDirInNewTab:(id)sender {	// context only
    DirectoryItem *item = (DirectoryItem *)[self.dirTree focusedItem];
	[self.delegate treeViewController:self addNewTabAtDir:item];
}
- (IBAction)openDirInTerminal:(id)sender {	// context only
    DirectoryItem *item = (DirectoryItem *)[self.dirTree focusedItem];
	NSString *s = [NSString stringWithFormat:
				   @"tell application \"Terminal\" to do script \"cd \'%@\'\"", item.fullPath];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
	[as executeAndReturnError:nil];
}
- (IBAction)getDirInfo:(id)sender {	// context & menu
    DirectoryItem *item;
    if ([sender isKindOfClass:[MyWindowController class]])
		item = [self.dirTree itemAtRow:[self.dirTree selectedRow]];
	else
		item = (DirectoryItem *)[self.dirTree focusedItem];
	NSString *s = [NSString stringWithFormat:
				   @"tell application \"Finder\"\n"
                   "open information window of %@  POSIX file \"%@\"\n"
                   "activate information window\n"
                   "end tell",  item.isAlias ? @"alias file" : (item.isPackage ? @"package" : @"folder"), item.fullPath];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
    NSDictionary *errorInfo;
	if(![as executeAndReturnError:&errorInfo])
        NSLog(@"errorInfo %@", errorInfo);
}
- (IBAction)addDirToSidebar:(id)sender {	// context only
    DirectoryItem *item = (DirectoryItem *)[self.dirTree focusedItem];
	[self.delegate treeViewController:self addToSidebar:item.fullPath];
}
- (IBAction)showTargetDir:(id)sender {	// context only
    DirectoryItem *item = (DirectoryItem *)[self.dirTree focusedItem];
	if(item.isAlias) {
		NSString *target = getTarget(item.fullPath);
		DirectoryItem *targetDir = findPathInVolumes(target);
		if(targetDir)	[self.delegate treeViewController:self addNewTabAtDir:targetDir];
		return;
	}
}
- (IBAction)symlinkToDir:(id)sender {
    DirectoryItem *item = (DirectoryItem *)[self.dirTree focusedItem];
	if (item == nil)    return;
    [self symlinkTo:item];
}
- (IBAction)setNewRoot:(id)sender {
    DirectoryItem *item;
    if ([sender isKindOfClass:[MyWindowController class]])
		item = [self.dirTree itemAtRow:[self.dirTree selectedRow]];
	else
		item = (DirectoryItem *)[self.dirTree focusedItem];
	[self setTreeRootNode:item];
}

#pragma mark NSPathControl Menu Actions
- (IBAction)copyPath:(id)sender {	// context & menu
	NSURL *url = [[self.currentPath clickedPathComponentCell] URL];
	[self copyToPasteboard:url];
}
- (IBAction)copyPathToClipboard:(id)sender {	// context only
	NSURL *url = [[self.currentPath clickedPathComponentCell] URL];
	[self copyToPasteboard:url.path];
}
- (IBAction)openPath:(id)sender {	// context & menu
	NSURL *url = [[self.currentPath clickedPathComponentCell] URL];
	LSOpenCFURLRef((__bridge CFURLRef)url, nil);
}
- (IBAction)revealPathInFinder:(id)sender {	// context & menu
	NSURL *url = [[self.currentPath clickedPathComponentCell] URL];
	[[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:url]];
}
- (IBAction)openPathInNewTab:(id)sender {	// context only
	NSURL *url = [[self.currentPath clickedPathComponentCell] URL];
	[self.delegate treeViewController:self addNewTabAtDir:findPathInVolumes(url.path)];
}
- (IBAction)openPathInTerminal:(id)sender {	// context only
	NSURL *url = [[self.currentPath clickedPathComponentCell] URL];
	NSString *s = [NSString stringWithFormat:
				   @"tell application \"Terminal\" to do script \"cd \'%@\'\"", url.path];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
	[as executeAndReturnError:nil];
}
- (IBAction)getPathInfo:(id)sender {	// context & menu
	NSURL *url = [[self.currentPath clickedPathComponentCell] URL];
	NSString *s = [NSString stringWithFormat:
				   @"tell application \"Finder\"\n"
                   "open information window of %@  POSIX file \"%@\"\n"
                   "activate information window\n"
                   "end tell",  @"folder", url.path];
	NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
    NSDictionary *errorInfo;
	if(![as executeAndReturnError:&errorInfo])
        NSLog(@"errorInfo %@", errorInfo);
}

#pragma mark - logging
- (void)expandBranch:(id)item {
	[self runBlockOnQueue:^{
		currentlyLogging = YES;
		[item logBranch];
		currentlyLogging = NO;
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{	// queue expand on main queue to update display
			[self.dirTree expandItem:item expandChildren:YES];
		}];
	}];
}
- (void)expandDir:(id)item {
//	NSLog(@"expandDir %@", [(DirectoryItem *)item loggedSubDirectories]);
	if ([item isDirPlus1Loaded])	return;	// already Loaded
//	NSLog(@"Not Loaded");
	[self runBlockOnQueue:^{
		[item logDirPlus1];
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self.dirTree expandItem:item];
		}];
	}];
	return;
}

#pragma mark - Delegate Actions
- (BOOL)keyPressedInOutlineView:(unichar)character shifted:(BOOL)shifted {
	if (shifted && character == NSF3FunctionKey) {
		[self.selectedDir updateDirectory];
		[self reloadData];
		return YES;
	}
	if (character == NSF3FunctionKey) {
		[self.selectedDir updateDirectory];
		[self updateBranchInQueue:self.selectedDir];
		return YES;
	}
	if (character == 0x0d) {
		[self enterFileView];
		return YES;
	}
	if (character == '*') {
        [self expandBranch:self.selectedDir];
		return YES;
	}
	if (character == '+' || character == '=') {
        [self expandDir:self.selectedDir];
		return YES;
	}
	if (character == '-') {
        [self.dirTree collapseItem:self.selectedDir collapseChildren:YES];
		[self.selectedDir releaseDir];
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
- (void)validateContextMenu:(NSMenu *)menu {
    DirectoryItem *item = (DirectoryItem *)[self.dirTree focusedItem];
	NSMenuItem *mi = [menu itemWithTitle:@"Show Target"];
	if(mi) [mi setHidden:!item.isAlias];
	mi = [menu itemWithTitle:@"Create Symlink"];
	if(mi) [mi setHidden:item.isAlias];
}

#pragma mark - NSOutlineViewDelegate Protocol methods
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldExpandItem:(id)item {
	if(currentlyLogging)	return NO;
    if([[NSApp currentEvent] modifierFlags] & NSAlternateKeyMask) {
        [self expandBranch:item];
		return NO;
	}
	return YES;
}
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
    [self updateSelectedDir];
}
- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
		if ([cell isKindOfClass:[ImageAndTextCell class]]) {
			if(![item nodeIcon]) {
				NSImage *fileIcon = [[NSWorkspace sharedWorkspace] iconForFile:[item fullPath]];
				[item setNodeIcon:fileIcon];
				if([item isAlias]) {	// Check for alias
					if ([NSImage respondsToSelector:@selector(imageWithSize:flipped:drawingHandler:)]) {
						NSImage *badgedFileIcon = [NSImage imageWithSize:fileIcon.size flipped:NO
														  drawingHandler:^BOOL (NSRect dstRect){
															  [fileIcon drawAtPoint:dstRect.origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
															  [aliasBadge drawAtPoint:dstRect.origin fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1];
															  return YES;
														  }];
						[item setNodeIcon:badgedFileIcon];
					}
				}
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
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldTypeSelectForEvent:(NSEvent *)event withCurrentSearchString:(NSString *)searchString {
	unichar keyChar = [[event charactersIgnoringModifiers] characterAtIndex:0];
	if(([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask && [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:keyChar])
		return YES;
	if([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:keyChar])
		return YES;
	return NO;
}
- (NSString *)outlineView:(NSOutlineView *)outlineView typeSelectStringForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	return ([[tableColumn identifier] isEqualToString:COLUMNID_NAME]) ? [item valueForKey:[tableColumn identifier]] : nil;
}

#pragma mark NSOutlineViewDataSource Protocol methods
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    return (item == nil) ? 1 : [item numberOfSubDirs];	// nil has 1 child - dataRoot
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
//    return (item == nil) ? YES : ([item numberOfSubDirs] != 0);
	return (item == nil) ? YES : [(DirectoryItem *)item isDirectoryExpandable];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    return (item == nil) ? dataRoot : [(DirectoryItem *)item directoryAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
   return (id)[item valueForKey:[tableColumn identifier]];
}

@end