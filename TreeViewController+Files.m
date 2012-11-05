//
//  TreeViewController+Files.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 1/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "TreeViewController+Files.h"
#import "MyWindowController.h"
#import "DirectoryItem.h"
#import "FileItem.h"
#import "ImageAndTextCell.h"
#import "OpenWith.h"
#import "DeletedItems.h"
#import "SearchPanelController.h"
#import "TextViewerController.h"

@interface TreeViewController()
//  TreeViewController
- (BOOL)areFilesTagged;
- (void)applyFileAndTagFilter:(NSPredicate *)filePredicate;
- (void)setFileMenu;
- (void)enterFileView;
- (void)enterDirView;
- (BOOL)restoreSplitView;
- (void)copyToPasteboard: (id)object;
- (void)toggleTopSubView:(id)sender;
- (void)setPanel;
//  TreeViewController+Copy
- (void)copyTo:(FileSystemItem *)node;
- (void)moveTo:(FileSystemItem *)node;
- (void)renameTo:(FileSystemItem *)node;
- (void)copyTaggedTo:(NSArray *)objectsToCopy;
- (void)moveTaggedTo:(NSArray *)objectsToCopy;
- (void)renameTaggedTo:(NSArray *)objects;
@end

@implementation TreeViewController(Files)
- (FileItem *)selectedFile {
    NSArray *selection = [self.arrayController selectedObjects];
    if ([selection count] == 1) return [selection objectAtIndex:0];
    return nil;
}
- (void)selectObject:(id)object {
    [self.fileList selectRowIndexes:[NSIndexSet indexSetWithIndex:[[self.arrayController arrangedObjects] indexOfObject:object]] byExtendingSelection:NO];
}
// tag or untag File from keyboard
- (void)tagFile:(BOOL)tagValue {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    node.tag = tagValue;
    [self.arrayController selectNext:self];
}
- (void)tagFiles:(BOOL)tagValue {
	NSArray *currentContents = [self.arrayController arrangedObjects];
	for (FileItem *node in currentContents) {
		node.tag = tagValue;
	}
}
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqual:@"operationCount"]) {
        NSNumber *noObjects = (__bridge NSNumber *)(context);
        NSNumber *ops = [change objectForKey:NSKeyValueChangeNewKey];
            [self.progress setDoubleValue:[noObjects doubleValue] - [ops doubleValue]];
        if ([ops integerValue] == 0) {
            [object removeObserver:self forKeyPath:keyPath];
            [self.progress setHidden:YES];
            [self.progress setIndeterminate:YES];
        }
    }
}
- (void)searchTagged {
    NSArray *objectsToSearch = [[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate];
	SearchPanelController *searchPanel = [SearchPanelController singleton];
    NSUInteger noObjects = [objectsToSearch count];
	if ([searchPanel runModal] == NSOKButton) {
        NSOperationQueue *searchQueue = [NSOperationQueue new];
        [searchQueue setMaxConcurrentOperationCount:10];
        [self.progress setIndeterminate:NO];
        [self.progress setMaxValue:noObjects];
        [self.progress setHidden:NO];
        [self.progress setBezeled:YES];
        NSString *searchString = searchPanel.searchString;
        NSString *searchArguments = searchPanel.searchArguments;
       
		for (FileItem *node in objectsToSearch) {
            [searchQueue addOperationWithBlock:^{
                NSTask *task = [[NSTask alloc] init];
                [task setLaunchPath: @"/usr/bin/grep"];
                NSArray *arguments = [NSArray arrayWithObjects: searchArguments, searchString, [node fullPath], nil];
                [task setArguments:arguments];
                [task launch];
                [task waitUntilExit];
                int status = [task terminationStatus];
                if (status) {
                        node.tag = NO;
                }
            }];
            
        }
        [searchQueue addObserver:self
                      forKeyPath:@"operationCount"
                         options:NSKeyValueObservingOptionNew
                         context:(__bridge void *)([NSNumber numberWithInteger:noObjects])];
	}
}
- (BOOL)isPackage {
    FileItem *node = [self selectedFile];
	if (node == nil)    return NO;
    return (node.fileSize == nil);
}

#pragma mark Menu Actions
- (void)tagOneFile {
	[self tagFile:YES];
}
- (void)untagOneFile {
	[self tagFile:NO];
}
- (void)tagAllFiles {
	[self tagFiles:YES];
}
- (void)untagAllFiles {
	[self tagFiles:NO];
}
- (void)invertTaggedFiles {
	NSArray *currentContents = [self.arrayController arrangedObjects];
	for (FileItem *node in currentContents) {
		node.tag = !node.tag;
	}
}
- (void)copyFileTo {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    [self copyTo:node];
}
- (void)copyTaggedFilesTo {
	NSArray *objectsToCopy = [[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate];
	[self copyTaggedTo:objectsToCopy];
}
- (void)moveFileTo {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    [self moveTo:node];
}
- (void)moveTaggedFilesTo {
	NSArray *objectsToMove = [[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate];
	[self moveTaggedTo:objectsToMove];
}
- (void)renameFile {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    [self renameTo:node];
}
- (void)renameTaggedFilesTo {
	NSArray *objectsToRename = [[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate];
	[self renameTaggedTo:objectsToRename];
}
- (void)moveTaggedToTrash {
	NSArray *taggedContents = [[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate];
	NSMutableArray *filesToDelete = [[NSMutableArray alloc] initWithCapacity:[taggedContents count]];
	for (FileItem *node in taggedContents) {
		[filesToDelete addObject:node.url];
	}
	[self.delegate treeViewController:self pauseRefresh:YES];
	[[NSWorkspace sharedWorkspace] recycleURLs:filesToDelete
							 completionHandler:^(NSDictionary *newURLs, NSError *error) {
								 for (FileItem *node in taggedContents) {
									 if([newURLs objectForKey:node.url]) {
                                         [[DeletedItems sharedDeletedItems] addWithPath:node.fullPath trashLocation:[[newURLs objectForKey:node.url] path]];
										 if (inBranch) {
											 NSMutableArray *files = [(DirectoryItem *)[node parent] files];
											 [files removeObject:node];
										 }
										 [self.filesInDir removeObject:node];
										 [self.arrayController rearrangeObjects];
									 }
								 }
								 [self.arrayController rearrangeObjects];
								 if (error) {
									 NSAlert *alert = [NSAlert alertWithError:error];
									 [alert runModal];
								 }
								 [self.delegate treeViewController:self pauseRefresh:NO];
							 } ];
}
- (BOOL)checkFileLocked:(FileItem *)node {
	NSFileManager *fileManager = [NSFileManager new];
	NSString *target = node.fullPath;
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:target error:nil];
    if ([fileAttributes fileIsImmutable]) {
        NSString *prompt = [NSString stringWithFormat:@"Item \"%@\" is Locked.", node.relativePath];
        NSAlert *locked = [NSAlert new];
        [locked setMessageText:prompt];
        [locked setInformativeText:@"Do you want to move it to Trash anyway?"];
        [locked setAlertStyle:NSWarningAlertStyle];
        [locked addButtonWithTitle:@"Continue"];
        [locked addButtonWithTitle:@"Stop"];
        NSInteger result = [locked runModal];
        if(result == NSAlertFirstButtonReturn) {
            fileAttributes = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:NSFileImmutable];
            [fileManager setAttributes:fileAttributes ofItemAtPath:target error:nil];
            return YES;
        } 
        return NO;
    }
    return YES;
}

- (void)moveToTrash {
	NSArray *selection = [self.arrayController selectedObjects];
	if ([selection count] == 1) {
		__block FileItem *node = [selection objectAtIndex:0];
        if (![self checkFileLocked:node])   return;
		NSArray *filesToDelete = [NSArray arrayWithObject:node.url];
		[self.delegate treeViewController:self pauseRefresh:YES];
		[[NSWorkspace sharedWorkspace] recycleURLs:filesToDelete
								 completionHandler:^(NSDictionary *newURLs, NSError *error) {
									 if (error == nil) {
                                         [[DeletedItems sharedDeletedItems] addWithPath:node.fullPath trashLocation:[[newURLs objectForKey:node.url] path]];
										 if (inBranch) {
											 NSMutableArray *files = [(DirectoryItem *)[node parent] files];
											 [files removeObject:node];
										 }
										 [self.filesInDir removeObject:node];
										 [self.arrayController rearrangeObjects];
                                         node = NULL;
									 }
									 else {
										 NSAlert *alert = [NSAlert alertWithError:error];
										 [alert runModal];
									 }
									 [self.delegate treeViewController:self pauseRefresh:NO];
								 } ];
	}
}

#pragma mark - Text Viewer
- (void)showFileInViewer {
    FileItem *node = [filesToView objectAtIndex:currentFileToView];
    [self selectObject:node];
    [textViewer initWithPath:[node fullPath]];
}
- (void)viewFiles:(NSArray *)files {
    filesToView = [files filteredArrayUsingPredicate:notEmptyPredicate];
    currentFileToView = 0;
	if ([filesToView count] == 0)   return;

    textViewer = [[TextViewerController alloc] 
                initWithNibName:@"TextView" 
                bundle:nil];
    [[self view] addSubview:[textViewer view]];	// embed new TextView in our host view
    [[textViewer view] setFrame:[[self view] bounds]];	// resize the controller's view to the host size
    textViewer.delegate = self;
    [self.fileList.window makeFirstResponder:textViewer.view];
    [self showFileInViewer];
}
- (void)exitFileViewer {
    [textViewer.view removeFromSuperview];
    textViewer = nil;
    [self.fileList.window makeFirstResponder:self.fileList];
}

#pragma mark - TextViewControllerDelegate
- (void)nextFile:(TextViewerController *)tvc {
    if ([filesToView count] <= currentFileToView + 1) return;
    currentFileToView++;
    [self showFileInViewer];
}
- (void)previousFile:(TextViewerController *)tvc {
    if (currentFileToView == 0) return;
    currentFileToView--;
    [self showFileInViewer];
}
- (void)exitTextView:(TextViewerController *)tvc {
    [self exitFileViewer];
}

#pragma mark Delegate Actions
- (void)mouseDownInTableView {
	if(!inFileView) {
		[self setFileMenu];
	}
}
- (BOOL)keyPressedInTableView:(unichar)character {
	if (character == 0x1b) {
		[self restoreSplitView];
		[self enterDirView];
		return YES;
	}
	if (character == 0x0d) {
		if ([self.splitViewTop isHidden]) {	// already in Full View
			[self restoreSplitView];
			[self enterDirView];
		}
		else	// go to Full View (must already be in File)
			[self toggleTopSubView:self];
		return YES;
	}
	if (character == 'v') {
        [self viewFiles:[self.arrayController selectedObjects]];
		return YES;
	}
	return NO;
}
- (BOOL)keyCmdPressedInTableView:(unichar)character {
//    NSLog(@"Cmd Key Press %x", character);
	return NO;
}
- (BOOL)keyCtlPressedInTableView:(unichar)character {
	if (character == 0x0d) {
        [self toggleShowTagged];
		return YES;
	}
	if (character == 's') {
        [self searchTagged];
		return YES;
	}
	if (character == 'v') {
        [self viewFiles:[[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate]];
		return YES;
	}
	return NO;
}
- (void)validateTableContextMenu:(NSMenu *)menu {
    FileItem *node = [self selectedFile];
    if (node == nil)    return;
    openWithClass = [[OpenWith alloc] initMenu:node.url];
	NSMenuItem *openWith = [menu itemWithTitle:@"Open With"];
	[openWith setSubmenu:[openWithClass openWithMenu]];
    NSMenuItem *packageContentsMenu = [menu itemWithTitle:@"Show Package Contents"];
    [packageContentsMenu setHidden:![self isPackage]];
}

#pragma mark Context Menu Actions
- (IBAction)copyFileToClipboard:(id)sender {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    [self copyToPasteboard:node.fullPath];
}
- (IBAction)copyFile:(id)sender {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    [self copyToPasteboard:node.url];
}
- (IBAction)copyTaggedFiles:(id)sender {
	NSArray *currentContents = [[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate];
	NSMutableArray *objectsToCopy = [[NSMutableArray alloc] initWithCapacity:[currentContents count]];
	for (FileItem *node in currentContents) {
		[objectsToCopy addObject:node.url];
	}
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
    [pasteboard writeObjects:objectsToCopy];
}
- (IBAction)openFile:(id)sender {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    LSOpenCFURLRef((__bridge CFURLRef)node.url, nil);
}
- (IBAction)revealFileInFinder:(id)sender {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:node.url]];
}
- (IBAction)getFileInfo:(id)sender {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    NSString *s = [NSString stringWithFormat:
                   @"tell application \"Finder\"\n"
                   "open information window of file  POSIX file \"%@\"\n"
                   "activate information window\n"
                   "end tell", node.fullPath];
    NSAppleScript *as = [[NSAppleScript alloc] initWithSource: s];
    [as executeAndReturnError:nil];		
}

- (IBAction)showPackageContents:(id)sender {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    DirectoryItem *fParent = node.parent;
    if ([fParent convertPackageToDirectory:node]) {
        [self.filesInDir removeObject:node];
        [self reloadData];
	}    
}
// FileView Double Click Target binding
- (IBAction)dClickFile:(id)sender {
	[self openFile:self];
}
#pragma mark - NSTableViewDelegate Protocol methods
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	if (inBranch) {
        FileItem *node = [self selectedFile];
        if (node) {
            self.currDir = [[node parent] url];
        }
	}
	if (quickLook) {
		if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
			[self setPanel];
		} else {
			quickLook = NO;
		}
	}
}

- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	if ([[tableColumn identifier] isEqualToString:COLUMNID_NAME]) {
		if ([cell isKindOfClass:[ImageAndTextCell class]]) {
			FileItem *node = [self.filesInDir objectAtIndex:rowIndex];
			if (node)
				if(![node nodeIcon]) {
					[node setNodeIcon:[[NSWorkspace sharedWorkspace] iconForFile:[node fullPath]]];
				}
			[(ImageAndTextCell*)cell setImage:[node nodeIcon]];	// set the cell's image
		}
	}
}
- (BOOL)tableView:(NSTableView *)tableView shouldReorderColumn:(NSInteger)columnIndex toColumn:(NSInteger)newColumnIndex {
    if (columnIndex == 0)   return NO;
    if (columnIndex == 1)   return NO;
    if (newColumnIndex == 0)    return NO;
    if (newColumnIndex == 1)    return NO;
    return YES;
}
@end