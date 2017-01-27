//
//  TreeViewController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 13/06/11.
//  Copyright 20111-2013 Ian Binnie. All rights reserved.
//

#import "TreeViewController.h"
#import "MyWindowController.h"
#import "volume.h"
#import "DirectoryItem.h"
#import "FileItem.h"
#import "ImageAndTextCell.h"
#import "NSString+Parse.h"
#import "IBDateFormatter.h"
#import "TextViewerController.h"

NSImage *aliasBadge;
NSPredicate *yesPredicate;
NSPredicate *tagPredicate;
NSPredicate *notEmptyPredicate;

@interface TreeViewController()
- (void)setTreeRootNode:(DirectoryItem *)node;
- (BOOL)restoreSplitView;
- (void)toggleTopSubView:(id)sender;
- (BOOL)areFilesVisible;
- (BOOL)isFileSelected;
- (void)setDirMenu;
- (void)setFileMenu;
- (void)enterFileView;
- (void)enterDirView;
- (BOOL)areFilesTagged;
- (void)setPanel;
- (void)applyFileAndTagFilter:(NSPredicate *)filePredicate;
@end
@interface TreeViewController(Filter)
- (void)checkFilter;
@end
@interface TreeViewController(Files)
- (FileItem *)selectedFile;
- (void)exitFileViewer;
@end
@interface TreeViewController(Dirs)
- (void)updateSelectedDir;
- (IBAction)setNewRoot:(id)sender;
@end
@interface TreeViewController(Copy)
- (void)runBlockOnQueue:(void (^)(void))block;
@end

@implementation TreeViewController
- (NSString *)getTargetFile {
	return[[self selectedFile] relativePath];
}
- (void)refreshCounters {
	NSArray *taggedObjects = [[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate];
	self.countTaggedFiles = [taggedObjects count];
}
+ (void)initialize {
	aliasBadge = [[NSImage alloc] initWithContentsOfFile:@"/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/AliasBadgeIcon.icns"];
	[aliasBadge setSize:NSMakeSize(32, 32)];
	yesPredicate = [NSPredicate predicateWithValue:YES];
	tagPredicate = [NSPredicate predicateWithFormat:@"SELF.tag == YES"];
    notEmptyPredicate = [NSPredicate predicateWithFormat:@"(SELF.fileSize > 0) AND (SELF.isPackage == NO)"];
	[NSApp registerServicesMenuSendTypes:[NSArray arrayWithObjects:(__bridge NSString *)kUTTypeDirectory,
										  (__bridge NSString *)kUTTypeFileURL,
										  nil]
							 returnTypes:[NSArray arrayWithObjects:(__bridge NSString *)kUTTypeDirectory,
										  (__bridge NSString *)kUTTypeFileURL,
										  nil]];
}
- (void)setRoot {
	[self setTreeRootNode:[self.selectedDir rootDir]];
}
- (NSString *)rootDirName {
	return [dataRoot relativePath];
}
// toggle the expanded/collapsed state of splitViewTop
- (void)toggleTopSubView:(id)sender {
	if(![self restoreSplitView]) {
		if([self isFileSelected]) {
			// Normal split - save position
			previousSplitViewHeight = [self.splitViewTop frame].size.height;
			[self.splitViewTop setHidden:YES];
			[self.fileList.window makeFirstResponder:self.fileList];
		}
	}
    [self.split adjustSubviews];
}
- (void)setPanel {
	NSArray *selection = [self.arrayController selectedObjects];
	if ([selection count] == 1) {
		[self.delegate treeViewController:self setPanelData:[NSArray arrayWithObject:[selection objectAtIndex:0]]];
	}
}

#pragma mark Toolbar Button Actions
- (void)segControlClicked:(id)sender {
    int clickedSegment = [sender selectedSegment];
    int clickedSegmentTag = [[sender cell] tagForSegment:clickedSegment];
	switch (clickedSegmentTag) {
		case 0:	// left - return to root directory
			[self setRoot];
//			[sender setEnabled:NO forSegment:0];
			break;
		case 1:	// middle - set new root directory
			[self setNewRoot:self];
//			[sender setEnabled:YES forSegment:0];
			break;
		case 2:	// toggle the File List View
			[self toggleTopSubView:self];
			[self enterFileView];
			break;
		default:
			break;
	}
}
// Make compound Predicate from file Predicate depending on state of showOnlyTagged
- (void)applyFileAndTagFilter:(NSPredicate *)filePredicate {
	if (filePredicate == yesPredicate)	filePredicate = nil;
	[self.fileList setUsesAlternatingRowBackgroundColors:filePredicate && !inBranch];
	if(showOnlyTagged && filePredicate) {
        [self.arrayController setFilterPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:filePredicate, tagPredicate, nil]]];
	} else	if(showOnlyTagged) {
        [self.arrayController setFilterPredicate:tagPredicate];
	} else
		[self.arrayController setFilterPredicate:filePredicate];
	[self checkFilter];
}
#pragma mark  Selectors
- (void)dClickPath:(id)sender {
    NSString *pp = [[[sender clickedPathComponentCell] URL] path];
    DirectoryItem *targetDir = findPathInVolumes(pp);
    [self restoreSplitView];    // back to normal Dir view if necessary
    [self setTreeRootNode:targetDir];
}
#pragma mark Menu Actions
- (void)togglePreviewPanel {
    if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
        [[QLPreviewPanel sharedPreviewPanel] orderOut:nil];
		quickLook = NO;
    } else {
        [[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFront:nil];
		quickLook = YES;
		[self setPanel];
    }
}
- (void)toggleShowTagged {
	showOnlyTagged = !showOnlyTagged;
	[self.delegate treeViewController:self tabState:showOnlyTagged];
	[self applyFileAndTagFilter:fileFilterPredicate];
}
- (void)toggleColumn:(id)sender {
	NSTableColumn *col = [sender representedObject];
	[col setHidden:![col isHidden]];
}

#pragma mark -
- (void)initViewHeaderMenu:(id)view {
    //create our contextual menu
    NSMenu *menu = [[view headerView] menu];
    //loop through columns, creating a menu item for each
    for (NSTableColumn *col in [view tableColumns]) {
        if ([[col identifier] isEqualToString:COLUMNID_NAME])
            continue;   // Cannot hide name column
        NSMenuItem *mi = [[NSMenuItem alloc] initWithTitle:[col.headerCell stringValue]
                                                    action:@selector(toggleColumn:)  keyEquivalent:@""];
        mi.target = self;
        mi.representedObject = col;
        [menu addItem:mi];
    }
    return;
}
- (void)saveTableColumns {
    NSTableColumn *col;
    NSArray *tables;
    NSString *identifier;
    tables = [self.fileList tableColumns];
    NSMutableDictionary *columnWidths = [NSMutableDictionary dictionaryWithCapacity:[tables count]];
    NSMutableDictionary *columnHidden = [NSMutableDictionary dictionaryWithCapacity:[tables count]];
    NSMutableArray *columnOrder = [NSMutableArray arrayWithCapacity:[tables count]];
    for (col in tables) {
        identifier = [[col headerCell] title];
        [columnWidths setObject:[NSNumber numberWithFloat:[col width]] forKey:identifier];
        [columnHidden setValue:[NSNumber numberWithBool:[col isHidden]] forKey:identifier];
        [columnOrder addObject:[col identifier]];
    }
	if (self.sidebyside) {
		[[NSUserDefaults standardUserDefaults] setObject:columnWidths forKey:PREF_FILE_RIGHT_COLUMN_WIDTH];
		[[NSUserDefaults standardUserDefaults] setObject:columnHidden forKey:PREF_FILE_RIGHT_COLUMN_HIDDEN];
		[[NSUserDefaults standardUserDefaults] setObject:columnOrder forKey:PREF_FILE_RIGHT_COLUMN_ORDER];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:columnWidths forKey:PREF_FILE_COLUMN_WIDTH];
		[[NSUserDefaults standardUserDefaults] setObject:columnHidden forKey:PREF_FILE_COLUMN_HIDDEN];
		[[NSUserDefaults standardUserDefaults] setObject:columnOrder forKey:PREF_FILE_COLUMN_ORDER];
	}
    tables = [self.dirTree tableColumns];
    columnWidths = [NSMutableDictionary dictionaryWithCapacity:[tables count]];
    columnHidden = [NSMutableDictionary dictionaryWithCapacity:[tables count]];
    columnOrder = [NSMutableArray arrayWithCapacity:[tables count]];
    for (col in tables) {
        [columnWidths setObject:[NSNumber numberWithFloat:[col width]] forKey:[[col headerCell] title]];
        [columnHidden setValue:[NSNumber numberWithBool:[col isHidden]] forKey:[[col headerCell] title]];
        [columnOrder addObject:[col identifier]];
    }
	if (self.sidebyside) {
		[[NSUserDefaults standardUserDefaults] setObject:columnWidths forKey:PREF_DIR_LEFT_COLUMN_WIDTH];
		[[NSUserDefaults standardUserDefaults] setObject:columnHidden forKey:PREF_DIR_LEFT_COLUMN_HIDDEN];
		[[NSUserDefaults standardUserDefaults] setObject:columnOrder forKey:PREF_DIR_LEFT_COLUMN_ORDER];
	}
	else {
		[[NSUserDefaults standardUserDefaults] setObject:columnWidths forKey:PREF_DIR_COLUMN_WIDTH];
		[[NSUserDefaults standardUserDefaults] setObject:columnHidden forKey:PREF_DIR_COLUMN_HIDDEN];
		[[NSUserDefaults standardUserDefaults] setObject:columnOrder forKey:PREF_DIR_COLUMN_ORDER];
	}
}
- (void)updateDateColumns:(NSNotification *)notification {
    NSString *identifier;
    NSDictionary *widths = [[NSUserDefaults standardUserDefaults] dictionaryForKey:PREF_DATE_WIDTH];
    if (widths)
        for (identifier in widths) {
            [[self.fileList tableColumnWithIdentifier:identifier] setWidth:[[widths objectForKey:identifier] floatValue]];
            [[self.dirTree tableColumnWithIdentifier:identifier] setWidth:[[widths objectForKey:identifier] floatValue]];
            [self.fileList sizeToFit];
            [self.dirTree sizeToFit];
        }
}
- (void)restoreColumns {
    NSString *identifier;
    NSTableColumn *col;
    NSDictionary *columnDefaults;
	NSArray *columnOrder;
	NSArray *tables;
	NSDictionary *widths;

	tables = [self.fileList tableColumns];
	widths = [[NSUserDefaults standardUserDefaults] dictionaryForKey:PREF_DATE_WIDTH];
	columnDefaults = [[NSUserDefaults standardUserDefaults] dictionaryForKey:self.sidebyside ? PREF_FILE_RIGHT_COLUMN_WIDTH : PREF_FILE_COLUMN_WIDTH];
    if (columnDefaults)
        for (col in tables) {
            identifier = [[col headerCell] title];
            [col setWidth:[[columnDefaults objectForKey:identifier] floatValue]];
        }
    else if (widths)
        for (identifier in widths) {
            [[self.fileList tableColumnWithIdentifier:identifier] setWidth:[[widths objectForKey:identifier] floatValue]];
        }

	columnDefaults = [[NSUserDefaults standardUserDefaults] dictionaryForKey:self.sidebyside ? PREF_FILE_RIGHT_COLUMN_HIDDEN : PREF_FILE_COLUMN_HIDDEN];
    if (columnDefaults)
        for (col in tables) {
            identifier = [[col headerCell] title];
            [col setHidden:[[columnDefaults objectForKey:identifier] boolValue]];
        }
	columnOrder = [[NSUserDefaults standardUserDefaults] arrayForKey:self.sidebyside ? PREF_FILE_RIGHT_COLUMN_ORDER : PREF_FILE_COLUMN_ORDER];
	if (columnOrder) {
		NSUInteger indx = 2;
		for (NSUInteger index = indx; index < [columnOrder count]; index++) {
			identifier = [columnOrder objectAtIndex:index];
			NSInteger colIndex = [self.fileList columnWithIdentifier:identifier];
			if (colIndex < 0)	continue;
			if (indx != colIndex)
				[self.fileList moveColumn:colIndex toColumn:indx];
			indx++;
		}
	}
    [self.fileList sizeToFit];

    tables = [self.dirTree tableColumns];
    columnDefaults = [[NSUserDefaults standardUserDefaults] dictionaryForKey:self.sidebyside ? PREF_DIR_LEFT_COLUMN_WIDTH : PREF_DIR_COLUMN_WIDTH];
    if (columnDefaults)
        for (col in tables) {
            identifier = [[col headerCell] title];
            [col setWidth:[[columnDefaults objectForKey:identifier] floatValue]];
        }
    else if (widths)
        for (identifier in widths) {
            [[self.dirTree tableColumnWithIdentifier:identifier] setWidth:[[widths objectForKey:identifier] floatValue]];
        }
    columnDefaults = [[NSUserDefaults standardUserDefaults] dictionaryForKey:self.sidebyside ? PREF_DIR_LEFT_COLUMN_HIDDEN : PREF_DIR_COLUMN_HIDDEN];
    if (columnDefaults)
        for (col in tables) {
            identifier = [[col headerCell] title];
            [col setHidden:[[columnDefaults objectForKey:identifier] boolValue]];
        }
    columnOrder = [[NSUserDefaults standardUserDefaults] arrayForKey:self.sidebyside ? PREF_DIR_LEFT_COLUMN_ORDER : PREF_DIR_COLUMN_ORDER];
    if (columnOrder) {
		NSUInteger indx = 1;
        for (NSUInteger index = indx; index < [columnOrder count]; index++) {
            identifier = [columnOrder objectAtIndex:index];
            NSInteger colIndex = [self.dirTree columnWithIdentifier:identifier];
			if (colIndex < 0)	continue;
            if (indx != colIndex)
				[self.dirTree moveColumn:colIndex toColumn:indx];
			indx++;
        }
	}
	Class cls = NSClassFromString (@"NSByteCountFormatter");
	if (cls) {
		NSByteCountFormatter *newForm = [NSByteCountFormatter new];
		if ([NSByteCountFormatter instancesRespondToSelector:
			 @selector (setAllowsNonnumericFormatting:)]) {
			newForm.allowsNonnumericFormatting = NO;
		}
		if([[NSUserDefaults standardUserDefaults] boolForKey:PREF_TOTAL_MODE]) {
			[[[self.dirTree tableColumnWithIdentifier:@"sizeOfFiles"] dataCell] setFormatter:newForm];
		}
		if([[NSUserDefaults standardUserDefaults] boolForKey:PREF_SIZE_MODE]) {
			[[[self.fileList tableColumnWithIdentifier:@"fileSize"] dataCell] setFormatter:newForm];
		}
	}
    [self.dirTree sizeToFit];
}
- (void)restoreSplit {
	if (self.sidebyside) {
		CGFloat defaultSplit = [[NSUserDefaults standardUserDefaults] floatForKey:PREF_SPLIT_PERCENTAGE_H];
		[self.split setPosition:[self.split frame].size.width * defaultSplit ofDividerAtIndex:0];
	} else {
		CGFloat defaultSplit = [[NSUserDefaults standardUserDefaults] floatForKey:PREF_SPLIT_PERCENTAGE];
		[self.split setPosition:[self.split frame].size.height * defaultSplit ofDividerAtIndex:0];
	}
}

- (void)awakeFromNib {
	self.sidebyside = [[NSUserDefaults standardUserDefaults]boolForKey:PREF_SPLIT_ORIENTATION];
	[self.split setVertical:self.sidebyside];
	[self restoreSplit];
	[self restoreColumns];

	// make our outline view appear with gradient selection, and behave like the Finder, iTunes, etc.
	[self.dirTree setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	[self.split adjustSubviews];
	if([[NSUserDefaults standardUserDefaults] boolForKey:PREF_DIRECTORY_ICON]) {
        // apply custom ImageAndTextCell for rendering the first column's cells
		NSTableColumn *tableColumn = [self.dirTree tableColumnWithIdentifier:COLUMNID_NAME];
		ImageAndTextCell *imageAndTextCell = [[ImageAndTextCell alloc] init];
		[imageAndTextCell setEditable:YES];
		[tableColumn setDataCell:imageAndTextCell];
	}
	if([[NSUserDefaults standardUserDefaults] boolForKey:PREF_FILE_ICON]) {
        // apply custom ImageAndTextCell for rendering the first column's cells
		NSTableColumn *tableColumn = [self.fileList tableColumnWithIdentifier:COLUMNID_NAME];
		ImageAndTextCell *imageAndTextCell = [[ImageAndTextCell alloc] init];
		[imageAndTextCell setEditable:YES];
		[tableColumn setDataCell:imageAndTextCell];
	}
	[[[self.fileList tableColumnWithIdentifier:COLUMNID_DATE] dataCell] setFormatter:[IBDateFormatter sharedDateFormatter].writeDateFormatter];
	[[[self.dirTree tableColumnWithIdentifier:COLUMNID_DATE] dataCell] setFormatter:[IBDateFormatter sharedDateFormatter].writeDateFormatter];
	[[[self.fileList tableColumnWithIdentifier:COLUMNID_CREATION] dataCell] setFormatter:[IBDateFormatter sharedDateFormatter].createDateFormatter];
	[[[self.dirTree tableColumnWithIdentifier:COLUMNID_CREATION] dataCell] setFormatter:[IBDateFormatter sharedDateFormatter].createDateFormatter];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDateColumns:) name:PreferencesControllerDateWidthsDidChangeNotification object:nil];

	savedSearchString =	[NSString string];
	showOnlyTagged = NO;
	fileFilterPredicate = yesPredicate;
	inFileView = NO;
	inBranch = NO;
    [self initViewHeaderMenu:self.fileList];
    [self initViewHeaderMenu:self.dirTree];
    [self restoreColumns];
	[self runBlockOnQueue:^{
		[dataRoot logDir];	// Force logging of root
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			[self expandRoot];
		}];
	}];
    [self.currentPath setDoubleAction:@selector(dClickPath:)];
    [self.currentPath setTarget:self];
}
// activate TreeView - initialisation on creation or reactivation
- (void)activateTreeView {
    [self.dirTree reloadData];
    [self updateSelectedDir];
	if (inFileView) {
        if (textViewer) {
            [self.fileList.window makeFirstResponder:textViewer.view];
        } else {
            [self.fileList.window makeFirstResponder:self.fileList];
            [self.delegate treeviewDidEnterFileWindow:self];
        }
	} else {
		[self.dirTree.window makeFirstResponder:self.dirTree];
		[self.delegate treeviewDidEnterDirWindow:self];
	}
	[self.delegate treeViewController:self tabState:showOnlyTagged];
	[self.delegate treeViewController:self filterValue:savedSearchString];
	[self applyFileAndTagFilter:fileFilterPredicate];	//******************* restore filter
}
- (void)suspendTreeView {
		[self.arrayController setFilterPredicate:nil];	// suspend processor intensive operations
}
- (BOOL)shouldTerminate {
	if (inFileView)
        if (textViewer) {
            [self exitFileViewer];
            return NO;  // exit textViewer but do not quit
        }
    return YES;
}

- (void)reloadData {
	[self.dirTree reloadData];
	[self.arrayController rearrangeObjects];
}
- (void)toggleView {
	[self.split setVertical:![self.split isVertical]];
	self.sidebyside = !self.sidebyside;
	[self restoreSplit];
	[self.split adjustSubviews];
	[self restoreColumns];
}
#pragma mark Delegate Actions - Services Support
- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard types:(NSArray *)types {
	if (inFileView)
		return [pboard setString:[[[self selectedFile] url] absoluteString] forType:(__bridge NSString *)kUTTypeFileURL];
	else
		return [pboard setString:[[[self selectedDir] url] absoluteString] forType:(__bridge NSString *)kUTTypeFileURL];
}
- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
    if ([sendType isEqual:(__bridge NSString *)kUTTypeFileURL])
            return self;
	return nil;
}

#pragma mark NSMenu Delegate Methods
-(void)menuWillOpen:(NSMenu *)menu {
	for (NSMenuItem *mi in menu.itemArray) {
		NSTableColumn *col = [mi representedObject];
		[mi setState:col.isHidden ? NSOffState : NSOnState];
	}
}

#pragma mark Private Methods
// There are files visible in List View (files in Dir which pass Filter predicate)
- (BOOL)areFilesVisible {
	NSArray *currentContents = [self.arrayController arrangedObjects];
	return ([currentContents count] > 0);
}
// There is a file in List View
- (BOOL)isFileSelected {
	NSArray *selection = [self.arrayController selectedObjects];
	return ([selection count] == 1);
}
- (BOOL)areFilesTagged {
	NSArray *currentContents = [[self.arrayController arrangedObjects] filteredArrayUsingPredicate:tagPredicate];
	return ([currentContents count] > 0);
}
- (void)setDirMenu {
	if (inFileView) {
		[self.delegate treeviewDidEnterDirWindow:self];
	}
	inFileView = NO;
	if (inBranch) {
        [self updateSelectedDir];
		self.filesInDir = self.selectedDir.files;
        [self.fileList setBackgroundColor:[NSColor controlBackgroundColor]];
		if([self.arrayController filterPredicate] && [self.arrayController filterPredicate] != tagPredicate)	[self.fileList setUsesAlternatingRowBackgroundColors:YES];
	}
	inBranch = NO;
}
- (void)setFileMenu {
	if (!inFileView) {
		[self.delegate treeviewDidEnterFileWindow:self];
	}
	inFileView = YES;
}
- (void)enterDirView {
	[self.dirTree.window makeFirstResponder:self.dirTree];
	[self setDirMenu];
}
- (void)enterFileView {
	if(![self isFileSelected]) {
		[self.arrayController setSelectionIndex:0];
	}
	if([self areFilesVisible]) {
		[self.fileList.window makeFirstResponder:self.fileList];
		[self setFileMenu];
	}
}
- (DirectoryItem *)treeRootNode {
	return dataRoot;
}
- (void)initWithDir:(DirectoryItem *)node {
	[self setRenameMask:@"*.*"];	// init default
	dataRoot = node;
}
- (void)expandRoot {
	[self enterDirView];
	[self.dirTree reloadData];
	self.selectedDir = dataRoot;
	[self.dirTree expandItem:dataRoot];
	self.filesInDir = dataRoot.files;
    self.currDir = dataRoot.url;
	[self.delegate treeViewController:self rootChangedInTreeView:[self rootDirName]];
}
- (void)setTreeRootNode:(DirectoryItem *)node {
	if (dataRoot == node) {
		return;
	}
	dataRoot = node;
	[self expandRoot];
}
// restore Tree in SplitView; return YES if restored
- (BOOL)restoreSplitView {
	if ([self.splitViewTop isHidden]) {
		[self.splitViewTop setHidden:NO];
        [self.split setPosition:previousSplitViewHeight ofDividerAtIndex:0];
		return YES;
	}
	return NO;
}
- (void)copyToPasteboard:(id)object {
	NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
	[pasteboard clearContents];
	NSArray *objectsToCopy = [NSArray arrayWithObject:object];
    [pasteboard writeObjects:objectsToCopy];
}

@end