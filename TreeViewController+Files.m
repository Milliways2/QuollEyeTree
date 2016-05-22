//
//  TreeViewController+Files.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 1/10/11.
//  Copyright 2011-2013 Ian Binnie. All rights reserved.
//

#import "TreeViewController+Files.h"
#import "MyWindowController.h"
#import "DirectoryItem.h"
#import "FileItem.h"
#import "volume.h"
#import "alias.h"
#import "ImageAndTextCell.h"
#import "OpenWith.h"
#import "DeletedItems.h"
#import "SearchPanelController.h"
#import "TextViewerController.h"
#import "CompareFileController.h"
#import "CompareFilterController.h"

extern NSPredicate *tagPredicate;
extern NSPredicate *notEmptyPredicate;

@interface TreeViewController()
- (void)setFileMenu;
- (void)enterFileView;
- (void)enterDirView;
- (BOOL)restoreSplitView;
- (void)copyToPasteboard: (id)object;
- (void)toggleTopSubView:(id)sender;
- (void)setPanel;
@end
@interface TreeViewController(Copy)
- (void)initPanelDest:(id)panel;
- (void)runBlockOnQueue:(void (^)(void))block;
- (void)copyTo:(FileSystemItem *)node;
- (void)moveTo:(FileSystemItem *)node;
- (void)renameTo:(FileSystemItem *)node;
- (void)copyTaggedTo:(NSArray *)objectsToCopy;
- (void)moveTaggedTo:(NSArray *)objectsToCopy;
- (void)renameTaggedTo:(NSArray *)objects;
- (void)batchForTagged:(NSArray *)objectsToCopy;
- (void)symlinkTo:(FileSystemItem *)node;
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
- (void)unTagFiles {
	NSArray *currentContents = [self.arrayController arrangedObjects];
	if(showOnlyTagged) {
		[self toggleShowTagged];
	}
	for (FileItem *node in currentContents) {
		node.tag = NO;
	}
}
- (void)tagFiles:(BOOL)tagValue {
	NSArray *currentContents = [self.arrayController arrangedObjects];
	// Need to pause Tag filtering on untag to prevent excessive processor use
	if(showOnlyTagged && !tagValue) {
		[self toggleShowTagged];
	}
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
- (NSArray *)taggedFiles {
	return[[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate];
}
- (void)searchTagged {
	NSArray *objectsToSearch = self.taggedFiles;
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
	[self unTagFiles];
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
	[self copyTaggedTo:self.taggedFiles];
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
	[self renameTaggedTo:self.taggedFiles];
}
// New 2015-06-19
- (void)batchForTaggedFiles {
	[self batchForTagged:self.taggedFiles];
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

// 2015-03-14 New delete - no Trash
- (void)deleteTagged {
	NSArray *taggedContents = [[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate];
	NSString *prompt = [NSString stringWithFormat:@"Warning: This will permanently delete \"%lu\" files.", [taggedContents count]];
	NSAlert *permremove = [NSAlert new];
	[permremove setMessageText:prompt];
	[permremove setAlertStyle:NSWarningAlertStyle];
	[permremove addButtonWithTitle:@"Continue"];
	[permremove addButtonWithTitle:@"Stop"];
	NSInteger result = [permremove runModal];
	if(result != NSAlertFirstButtonReturn) {
		return;
	}
	[self.delegate treeViewController:self pauseRefresh:YES];
	NSError *error = nil;
	NSFileManager *fileManager = [NSFileManager new];
	for (FileItem *node in taggedContents) {
		if([fileManager removeItemAtPath:node.fullPath error:&error]) {
			if (inBranch) {
				NSMutableArray *files = [(DirectoryItem *)[node parent] files];
				[files removeObject:node];
			}
			[self.filesInDir removeObject:node];
			[self.arrayController rearrangeObjects];
		} else {
		 NSAlert *alert = [NSAlert alertWithError:error];
		 [alert runModal];
		}
	}
	[self.delegate treeViewController:self pauseRefresh:NO];
}

- (void)moveToTrash {
	NSArray *selection = [self.arrayController selectedObjects];
	if ([selection count] == 1) {
		__block FileItem *node = [selection objectAtIndex:0];
        if (![self checkFileLocked:node])   return;
// 2015-03-13 test delete 10.8 or later
		NSURL *deletedURL;
		NSError *error;
		[self.delegate treeViewController:self pauseRefresh:YES];
		[[NSFileManager defaultManager] trashItemAtURL:node.url
									  resultingItemURL:&deletedURL
												 error:&error];
		if (error == nil) {
			[[DeletedItems sharedDeletedItems] addWithPath:node.fullPath
											 trashLocation:deletedURL.path];
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

	}
}
- (void)updateTargetNames:(id)sender target:(id)panel {
	NSArray *items = [[self.arrayController arrangedObjects] sortedArrayUsingComparator: ^(id obj1, id obj2) {
		return [((FileItem *)obj1).relativePath caseInsensitiveCompare:((FileItem *)obj2).relativePath];
	}];
	NSUInteger noItems = [items count];
	NSMutableArray *objects = [NSMutableArray arrayWithCapacity:noItems];
	for (FileItem *node in items) {
		[objects addObject:[node relativePath]];
	}
	[panel setTargetNames:objects];
	if (noItems == 0) return;
	NSUInteger destItem = [items indexOfObject:[self selectedFile]];
	if (sender == self) {
		NSArray *taggedItems = [items filteredArrayUsingPredicate:tagPredicate];
		if([taggedItems count] == 1)
			destItem = [items indexOfObject:[taggedItems objectAtIndex:0]];
	}
	[panel setTargetNames:objects];
	[panel setSelectedName:destItem];
}
- (void)pipeReadCompletionNotification:(NSNotification *)aNotification {
	NSData *data = [aNotification.userInfo objectForKey:NSFileHandleNotificationDataItem];
	if([data length] > 0) {
		textViewer = [[TextViewerController alloc]
					  initWithNibName:@"TextView"
					  bundle:nil];
		[[self view] addSubview:[textViewer view]];	// embed new TextView in our host view
		[[textViewer view] setFrame:[[self view] bounds]];	// resize the controller's view to the host size
		textViewer.delegate = self;
		[self.fileList.window makeFirstResponder:textViewer.view];
		[textViewer initWithData:data encoding:0];
	}
}
- (void)resetStatusMessage {
	[[self statusMessage] setHidden:YES];
}
- (void)postStatusMessage:(NSString *)message {
	[[self statusMessage] setStringValue:message];
	[[self statusMessage] setHidden:NO];
	[self performSelector:@selector(resetStatusMessage) withObject:nil afterDelay:5.0];
}
- (void)compareTo:(FileSystemItem *)node {
    CompareFileController *comparePanel = [CompareFileController new];
	comparePanel.delegate = self;
	[comparePanel setFrom:node.fullPath];
	[self initPanelDest:comparePanel];	// set target to directories in tabs
	[comparePanel setFilename:node.relativePath];
	if ([[node.fullPath stringByDeletingLastPathComponent] isEqualToString:comparePanel.targetDirectory]) {	// i.e. target is self
		[self updateTargetNames:self target:comparePanel];	// set names of files for self  directory
	}
	if ([comparePanel runModal] == NSOKButton) {
		targetDirectory = comparePanel.targetDirectory;
		NSString *source = [[self selectedFile] fullPath];
		NSString *target = [targetDirectory stringByAppendingPathComponent:comparePanel.filename];
		NSFileManager *fileManager = [NSFileManager new];
		if(![fileManager fileExistsAtPath:target]) {
			[self postStatusMessage:@"file does not exist"];
			return;
		}
		if([fileManager contentsEqualAtPath:source andPath:target]) {
			[self postStatusMessage:@"files are identical"];
			return;
		}
		NSTask *task = [[NSTask alloc] init];
		NSPipe *pipe = [NSPipe pipe];
		[task setStandardOutput: pipe];
		[task setStandardInput:[NSPipe pipe]];		//The magic line that keeps your log where it belongs
		NSFileHandle *file = [pipe fileHandleForReading];
		[task setLaunchPath: @"/bin/sh"];
		NSArray *arguments = [NSArray arrayWithObjects:
							  @"-c" ,
							  [[NSUserDefaults standardUserDefaults] stringForKey:PREF_COMPARE_COMMAND],
							  @"Compare",	// $0 place holder
							  source,
							  target,
							  nil];
		[task setArguments:arguments];
		[task setEnvironment:[NSDictionary dictionaryWithObject:@"/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin" forKey:@"PATH"]];

		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(pipeReadCompletionNotification:)
													 name:NSFileHandleReadCompletionNotification
												   object:file];
		[file readInBackgroundAndNotify];
		[task launch];
	}
    copyPanel = nil;
}
- (void)compareFile {
	[self compareTo:[self selectedFile]];
}
- (void)editFile {
	if(![[NSWorkspace sharedWorkspace] openFile:[[self selectedFile] fullPath]
								withApplication:[[NSUserDefaults standardUserDefaults] stringForKey:PREF_EDIT_COMMAND]])
		[self postStatusMessage:@"unable to open file"];
}
- (void)editTaggedFiles {
	for (FileItem *node in self.taggedFiles) {
		if(![[NSWorkspace sharedWorkspace] openFile:node.fullPath
									withApplication:[[NSUserDefaults standardUserDefaults] stringForKey:PREF_EDIT_COMMAND]])
			[self postStatusMessage:@"unable to open file"];
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
	[self.splitViewTop setHidden:YES];	// 2014-12-07 kludge to prevent Directory shading print through in Yosemite
    [[self view] addSubview:[textViewer view]];	// embed new TextView in our host view
    [[textViewer view] setFrame:[[self view] bounds]];	// resize the controller's view to the host size
    textViewer.delegate = self;
    [self.fileList.window makeFirstResponder:textViewer.view];
    [self showFileInViewer];
}
- (void)exitFileViewer {
    [textViewer.view removeFromSuperview];
    textViewer = nil;
//	[self.splitViewTop setHidden:NO];	// 2014-12-07 restore Directory view
	[self.splitViewTop setHidden:self->inBranch];	// 2015-03-30 restore Directory view (fix for Branch View)

    [self.fileList.window makeFirstResponder:self.fileList];
}

#pragma mark - CompareFileControllerDelegate
- (void)compareFileController:(CompareFileController *)cfc didSelectTabAtIndex:(NSInteger)index {
	TreeViewController *tvc = [self.delegate tvcAtIndex:index];
	[tvc updateTargetNames:self target:cfc];	// tell tvc to set names of files for selected target directory
}

#pragma mark TextViewControllerDelegate
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

#pragma mark Context Menu Actions
- (IBAction)copyFileToClipboard:(id)sender {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    [self copyToPasteboard:node.fullPath];
}
- (IBAction)copyFileNameToClipboard:(id)sender {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    [self copyToPasteboard:node.relativePath];
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
- (IBAction)showTarget:(id)sender {
    FileItem *node = [self selectedFile];
	if(node.isAlias) {
		NSString *target = getTarget(node.fullPath);
		if(![[NSFileManager defaultManager] fileExistsAtPath:target])	return;

		[self runBlockOnQueue:^{
			DirectoryItem *targetDir = locateOrAddDirectoryInVolumes([target stringByDeletingLastPathComponent]);
			if(targetDir) {
				[[NSOperationQueue mainQueue] addOperationWithBlock:^{
					TreeViewController *newTreeViewController = [self.delegate treeViewController:self addNewTabAtDir:targetDir];
					[newTreeViewController enterFileView];
					NSString *fileName = [target lastPathComponent];
					for (FileItem *element in targetDir.files) {
						if ([fileName compare:[element relativePath] options:NSCaseInsensitiveSearch] == NSOrderedSame) {
							[newTreeViewController selectObject:element];
							break;
						}
					}
				}];
			}
		}];
	}
}
- (IBAction)symlinkToFile:(id)sender {
    FileItem *node = [self selectedFile];
	if (node == nil)    return;
    [self symlinkTo:node];
}
// FileView Double Click Target binding
- (IBAction)dClickFile:(id)sender {
	[self openFile:self];
}
#pragma mark -
- (void)duplicateFiles {
	if(!inBranch)			return;
	CompareFilterController *searchPanel = [CompareFilterController new];
	if ([searchPanel runModal] != NSOKButton)	return;
	NSUInteger filterMode =	[searchPanel.filterMode selectedRow];
	if(filesInBranch == nil)	filesInBranch = [self.filesInDir copy];	// keep a copy of Branch contents
	NSArray *sortedContents = [[self.arrayController arrangedObjects] sortedArrayUsingComparator: ^(id obj1, id obj2) {
		return [((FileItem *)obj1).relativePath caseInsensitiveCompare:((FileItem *)obj2).relativePath];
	}];
	NSMutableIndexSet *all = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [sortedContents count])];
	NSMutableIndexSet *duplicates = [NSMutableIndexSet indexSet];

	NSString *name;
	NSUInteger index = [all firstIndex];
	NSUInteger lastIndex = [all lastIndex];
	while(index != NSNotFound) {
		name = [[sortedContents objectAtIndex:index] relativePath];
		NSIndexSet *multi = [all indexesInRange:NSMakeRange(index, lastIndex - index) options:0 passingTest:^(NSUInteger idx, BOOL *stop) {
			if([[[sortedContents objectAtIndex:idx] relativePath] isEqualToString:name])	return YES;
			*stop = YES;
			return NO;
		}];
		if ([multi count] > 1) {
			[all removeIndexes:multi];
			if(filterMode == DuplicateName) {
				[duplicates addIndexes:multi];	// normal duplicates
			} else {
				NSUInteger idx = [multi firstIndex];
				NSDate *oldestDate = [[sortedContents objectAtIndex:idx] wDate];
				NSDate *newestDate = oldestDate;
				while(idx != NSNotFound) {	// find Oldest, Newest Date
					NSDate *idxDate = [[sortedContents objectAtIndex:idx] wDate];
					oldestDate = [oldestDate earlierDate:idxDate];
					newestDate = [newestDate laterDate:idxDate];
					idx = [multi indexGreaterThanIndex: idx];
				}

				idx = [multi firstIndex];
				while(idx != NSNotFound) {
					NSDate *idxDate = [[sortedContents objectAtIndex:idx] wDate];
					if (filterMode == DuplicateIdenticalDate) {
						NSIndexSet *identical = [multi indexesPassingTest:^(NSUInteger iindx, BOOL *stop) {
							return (BOOL)([[[sortedContents objectAtIndex:iindx] wDate] timeIntervalSinceDate:idxDate] == 0);
						}];
						if ([identical count] > 1) {
							[duplicates addIndexes:identical];
						}
						//				[multi removeIndexes:identical];
					}
					if (filterMode == DuplicateOldestDate) {
						NSIndexSet *older = [multi indexesPassingTest:^(NSUInteger iindx, BOOL *stop) {
							return [[[sortedContents objectAtIndex:iindx] wDate] isEqualToDate:oldestDate];
						}];
						[duplicates addIndexes:older];
					}
					if (filterMode == DuplicateNewestDate) {
						NSIndexSet *newer = [multi indexesPassingTest:^(NSUInteger iindx, BOOL *stop) {
							return [[[sortedContents objectAtIndex:iindx] wDate] isEqualToDate:newestDate];
						}];
						[duplicates addIndexes:newer];
					}
					idx = [multi indexGreaterThanIndex: idx];
				}
			}
		}
		index = [all indexGreaterThanIndex: index];
	}
	if(filterMode == Unique) {	// Unique
		duplicates = all;
	}

	NSMutableArray *duplicateFiles = [NSMutableArray arrayWithCapacity:[duplicates count]];
	index = [duplicates firstIndex];
	while(index != NSNotFound) {
		[duplicateFiles addObject:[sortedContents objectAtIndex:index]];
		index = [duplicates indexGreaterThanIndex:index];
	}
	self.filesInDir = duplicateFiles;
}
#pragma mark Delegate Actions
- (void)mouseDownInTableView {
	if(!inFileView) {
		[self setFileMenu];
	}
}
// Most keys are set in MainWindow.xib and dispatched via MyWindowController+FileMenu
- (BOOL)keyPressedInTableView:(unichar)character {
	if (character == 0x1b) {
		if(filesInBranch) {
			self.filesInDir = filesInBranch;
			filesInBranch = nil;
			return YES;
		}
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
	if (character == 'j') {
        [self compareTo:[self selectedFile]];
		return YES;
	}
	return NO;
}
- (BOOL)keyCmdPressedInTableView:(unichar)character {
	return NO;
}
- (BOOL)keyAltPressedInTableView:(unichar)character {
	if (character == NSF4FunctionKey) {
		[self duplicateFiles];
		return YES;
	}
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
//	if (character == 'b') {
//		[self batchForTaggedFiles];
//		return YES;
//	}
	return NO;
}
- (void)validateTableContextMenu:(NSMenu *)menu {
    FileItem *node = [self selectedFile];
    if (node == nil)    return;
	if(node.isAlias) {
		NSString *target = getTarget(node.fullPath);
		if(target)
			openWithClass = [[OpenWith alloc] initMenu:[NSURL fileURLWithPath:target isDirectory:NO]];
	}
	else
		openWithClass = [[OpenWith alloc] initMenu:node.url];
	NSMenuItem *openWith = [menu itemWithTitle:@"Open With"];
	[openWith setSubmenu:[openWithClass openWithMenu]];
    NSMenuItem *mi = [menu itemWithTitle:@"Show Package Contents"];
    if(mi) [mi setHidden:!node.isPackage];
	mi = [menu itemWithTitle:@"Show Target"];
    if(mi) [mi setHidden:!node.isAlias];
	mi = [menu itemWithTitle:@"Create Symlink"];
	if(mi) [mi setHidden:node.isAlias];
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
//		[cell setTextColor:[NSColor blueColor]];
	}
}
- (BOOL)tableView:(NSTableView *)tableView shouldReorderColumn:(NSInteger)columnIndex toColumn:(NSInteger)newColumnIndex {
    if (columnIndex == 0)   return NO;
    if (columnIndex == 1)   return NO;
    if (newColumnIndex == 0)    return NO;
    if (newColumnIndex == 1)    return NO;
    return YES;
}
- (BOOL)tableView:(NSTableView *)tableView shouldTypeSelectForEvent:(NSEvent *)event withCurrentSearchString:(NSString *)searchString {
	unichar keyChar = [[event charactersIgnoringModifiers] characterAtIndex:0];
	if(([event modifierFlags] & NSShiftKeyMask) == NSShiftKeyMask && [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:keyChar])
		return YES;
	if([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:keyChar])
		return YES;
	return NO;
}
- (NSString *)tableView:(NSTableView *)tableView typeSelectStringForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return ([[tableColumn identifier] isEqualToString:COLUMNID_NAME]) ? [[tableView preparedCellAtColumn:1 row:row] stringValue] : nil;	// note COLUMNID_NAME is always 1
}
@end