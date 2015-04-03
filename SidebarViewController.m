//
//  SidebarController.m
//  Sidebar
//
//  Created by Ian Binnie on 26/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "SidebarViewController.h"
#import "BaseNode.h"
#import "ImageAndTextCell.h"
#import "PathHelper.h"
#import "SidebarViewControllerDelegate.h"
#import "MyOutlineView.h"

#define SIDEBAR_COLUMNID_NAME	@"NameColumn"	// the single column name in our outline view
// default folder titles
#define DEVICES_NAME			@"DEVICES"
#define PLACES_NAME				@"PLACES"

#define kNodesPBoardType		@"myNodesPBoardType"	// drag and drop pasteboard type

@interface SidebarViewController ()
- (void)initializeVolumeMonitoring;
@end

@implementation SidebarViewController
@synthesize delegate;

- (void)savePlaces {
	NSArray	*placesChildren = [[[[treeController arrangedObjects]descendantNodeAtIndexPath:places] representedObject] children];
	NSMutableArray *userPlaces = [NSMutableArray arrayWithCapacity:[placesChildren count]];
	for (BaseNode *place in placesChildren) {
		[userPlaces addObject:[place path]];
	}
	[[NSUserDefaults standardUserDefaults] setObject:userPlaces forKey:@"userPlaces"];
}

- (NSIndexPath *)addFolder:(NSString *)folderName {
	BaseNode *node = [[BaseNode alloc] init];
	[node setNodeTitle:folderName];

	NSIndexPath *indexPath = [NSIndexPath indexPathWithIndex:[sidebarContents count]]; //add the folder to the top-level at the end
	[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
	[treeController setSelectionIndexPath:indexPath];	// select newly inserted Folder
	return indexPath;
}
- (void)addDirectoryToFolder:(NSString *)directory {
	NSImage *iconImage = [[PathHelper sharedPathHelper] iconForPath:directory];
	BaseNode *node = [[BaseNode alloc] initLeaf];	// create a leaf node
	[node setPath:directory];
	[node setNodeIcon:iconImage];
	[node setNodeTitle:[[NSFileManager defaultManager] displayNameAtPath:directory]];

	// find the selection to insert our node
	NSIndexPath *indexPath;
	if ([[treeController selectedObjects] count] > 0) {
		// we have a selection, insert at the end of the selection
		indexPath = [treeController selectionIndexPath];
		indexPath = [indexPath indexPathByAddingIndex:[[[[treeController selectedObjects] objectAtIndex:0] children] count]];
	}
	else {
		indexPath = [NSIndexPath indexPathWithIndex:[sidebarContents count]];	// add the child to the end of the tree
	}
	[treeController insertObject:node atArrangedObjectIndexPath:indexPath];
}
- (void)addPlace:(NSString *)path {
	[treeController setSelectionIndexPath:places];	// select places Folder
	[self addDirectoryToFolder:path];
	[self savePlaces];
}

- (NSString *)homePlace:(NSString *)directory {
	return [NSHomeDirectory() stringByAppendingPathComponent:directory];
}

- (void)addPlacesSection {
	places = [self addFolder:PLACES_NAME];	// add the "Places" section
	// add its children
	NSArray *userPlaces = [[NSUserDefaults standardUserDefaults] arrayForKey:@"userPlaces"];
	if ([userPlaces count]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
		for (NSString *dir in userPlaces) {
            if([fileManager fileExistsAtPath:dir]) // only add if target exists
                [self addDirectoryToFolder:dir];
		}
	} else {
		[self addDirectoryToFolder:NSHomeDirectory()];
		[self addDirectoryToFolder:[self homePlace:@"Desktop"]];
		[self addDirectoryToFolder:@"/Applications"];
		[self addDirectoryToFolder:[self homePlace:@"Documents"]];
		[self savePlaces];
	}
}
- (void)addDevicesSection {
	devices = [self addFolder:DEVICES_NAME];	// insert the "Devices" group at the top of our tree
	// add mounted and removable volumes to the "Devices" group
	NSArray *mountedVols = [[NSFileManager new] mountedVolumeURLsIncludingResourceValuesForKeys:NULL options:NSVolumeEnumerationSkipHiddenVolumes];
	if ([mountedVols count] > 0) {
		for (NSURL *element in mountedVols)
			[self addDirectoryToFolder:[element path]];
	}
}
- (void)populateOutlineContents:(id)inObject {
	[myOutlineView setHidden:YES];	// hide the outline view - don't show it as we are building the contents
	[self addDevicesSection];		// add the "Devices" outline section
	[self addPlacesSection];		// add the "Places" outline section

	NSArray *selection = [treeController selectionIndexPaths];
	[treeController removeSelectionIndexPaths:selection];	// remove the current selection
	[myOutlineView setHidden:NO];
	[myOutlineView expandItem:nil expandChildren:YES];
}
- (IBAction)removeEntry:(id)sender {
	id item = [myOutlineView focusedItem];
	if (item) {
		[treeController removeObjectAtArrangedObjectIndexPath:[item indexPath]];
		[self savePlaces];
		return;
	}
	NSIndexPath *selection = [treeController selectionIndexPath];
	if (selection) {
		[treeController removeObjectAtArrangedObjectIndexPath:selection];
		[self savePlaces];
	}
}
#pragma mark - Context Menu Actions
- (void)openDirectory:(BOOL)inTab{
    id item = [myOutlineView focusedItem];
	if (item) {
		[self.delegate sidebarViewController:self shouldSelectDirectory:[[item representedObject] path] inTab:inTab];
		return;
	}
	NSArray *selection = [treeController selectedObjects];	// ask the tree controller for the current selection
	if ([selection count] == 1) {
		BaseNode *node = [selection objectAtIndex:0];
		[self.delegate sidebarViewController:self shouldSelectDirectory:[node path] inTab:inTab];
	}
}
- (IBAction)openEntryIntab:(id)sender {
	[self openDirectory:YES];
}
- (IBAction)openEntry:(id)sender {
	[self openDirectory:NO];
}
- (IBAction)ejectVolume:(id)sender {
	id item = [myOutlineView focusedItem];
	if (item) {
        [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:[[item representedObject] path]];
		return;
	}
}

- (void)awakeFromNib {
	// apply our custom ImageAndTextCell for rendering the first column's cells
	NSTableColumn *tableColumn = [myOutlineView tableColumnWithIdentifier:SIDEBAR_COLUMNID_NAME];
	ImageAndTextCell *imageAndTextCell = [[ImageAndTextCell alloc] init];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];

	[self populateOutlineContents:nil];
	[self initializeVolumeMonitoring];

	// make our outline view appear with gradient selection, and behave like the Finder, iTunes, etc.
	[myOutlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	// drag and drop support
	[myOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:
											kNodesPBoardType,			// our internal drag type
											nil]];
}

- (BOOL)isSpecialGroup:(BaseNode *)groupNode {
	return ([groupNode nodeIcon] == nil &&
			([[groupNode nodeTitle] isEqualToString:DEVICES_NAME] || [[groupNode nodeTitle] isEqualToString:PLACES_NAME]));
}

#pragma mark Monitor Volumes
- (void)addSidebarVolume:(NSString *)path {
	[treeController setSelectionIndexPath:devices];	// select devices Folder
	[self addDirectoryToFolder:path];
}
- (void)removeSidebarVolume:(NSString *)path {
	BaseNode *deviceNode = [[[treeController arrangedObjects] descendantNodeAtIndexPath:devices] representedObject];
	NSUInteger i = 0;
	for (BaseNode *volume in [deviceNode children]) {
		if ([[volume path] isEqualToString:path]) {
			[treeController removeObjectAtArrangedObjectIndexPath:[devices indexPathByAddingIndex:i]];
		}
		i++;
	}
}

void volumeEvents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]) {
    SidebarViewController *sidebar = (__bridge SidebarViewController *)userData;
	size_t i;
	for(i=0; i<numEvents; i++){
		if (eventFlags[i] == kFSEventStreamEventFlagMount) {
			[sidebar addSidebarVolume:[(__bridge NSArray *)eventPaths objectAtIndex:i]];
		}
		if (eventFlags[i] == kFSEventStreamEventFlagUnmount) {
			[sidebar removeSidebarVolume:[(__bridge NSArray *)eventPaths objectAtIndex:i]];
			[sidebar.delegate sidebarViewController:sidebar shouldRemoveVolume:[(__bridge NSArray *)eventPaths objectAtIndex:i]];	// notify delegate
		}
	}
}
// Watch /Volumes for changes
- (void)initializeVolumeMonitoring {
    NSArray *pathsToWatch = [NSArray arrayWithObject:@"/Volumes"];
    void *appPointer = (__bridge void *)self;
    FSEventStreamContext context = {0, appPointer, NULL, NULL, NULL};
    NSTimeInterval latency = 3.0;
	stream = FSEventStreamCreate(NULL,
	                             &volumeEvents_callback,
	                             &context,
	                             (__bridge CFArrayRef) pathsToWatch,
								 kFSEventStreamEventIdSinceNow,
	                             (CFAbsoluteTime) latency,
	                             kFSEventStreamCreateFlagUseCFTypes
								 );

	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
}

#pragma mark Delegate Actions
- (void)validateContextMenu:(NSMenu *)menu {
    id item = [myOutlineView focusedItem];
    if (item) {
        [[menu itemWithTag:5] setEnabled:[[item indexPath] indexPathByRemovingLastIndex] == places];    // Remove from Sidebar
        NSString *path = [[item representedObject] path];
        if (path) {
            BOOL removableFlag, writableFlag, unmountableFlag;
            NSString *description, *fileSystemType;
            [[NSWorkspace sharedWorkspace] getFileSystemInfoForPath:path isRemovable:&removableFlag isWritable:&writableFlag isUnmountable:&unmountableFlag description:&description type:&fileSystemType];
            NSMenuItem *menuItem = [menu itemWithTag:4];
            [menuItem setHidden:YES];
            if (unmountableFlag) {
                [menuItem setTitle:[NSString stringWithFormat:@"Eject \"%@\"", [path lastPathComponent]]];
                [menuItem setHidden:NO];
            }
        }
    }
}
#pragma mark NSOutlineView delegate
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item; {
	BaseNode* node = [item representedObject];
	return (![self isSpecialGroup:node]);	// don't allow special group nodes (Devices and Places) to be selected
}
- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	if ([[tableColumn identifier] isEqualToString:SIDEBAR_COLUMNID_NAME]) {
		// we are displaying the single and only column
		if ([cell isKindOfClass:[ImageAndTextCell class]]) {
			[(ImageAndTextCell*)cell setImage:[[item representedObject] nodeIcon]];	// set the cell's image
		}
	}
}
- (void)outlineViewSelectionDidChange:(NSNotification *)notification {
	NSArray *selection = [treeController selectedObjects];	// ask the tree controller for the current selection
	if ([selection count] == 1) {
		BaseNode *node = [selection objectAtIndex:0];
		if (![self isSpecialGroup:node]) {	// don't allow special group nodes (Devices and Places) to be selected
			[self.delegate sidebarViewController:self shouldSelectDirectory:[node path] inTab:NO];
            [myOutlineView deselectAll:self];
        }
	}
}

#pragma mark - NSOutlineView drag and drop
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
	return NSDragOperationMove;
}

- (BOOL)outlineView:(NSOutlineView *)ov writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	if ([[[items objectAtIndex:0] representedObject] path] == nil) return NO;	// don't allow folders to be dragged
	if ([[[items objectAtIndex:0] indexPath] indexPathByRemovingLastIndex] == devices) return NO;	// don't allow devices to be dragged
	[pboard declareTypes:[NSArray arrayWithObjects:kNodesPBoardType, nil] owner:self];
	self.dragNodesArray = items;	// keep track of this node for drag feedback in "validateDrop"
	return YES;
}
//	This method is used by NSOutlineView to determine a valid drop target.
- (NSDragOperation)outlineView:(NSOutlineView *)ov
				  validateDrop:(id <NSDraggingInfo>)info
				  proposedItem:(id)item
			proposedChildIndex:(NSInteger)index {
	NSDragOperation result = NSDragOperationNone;
	if (!item) {
		result = NSDragOperationNone;	// no item to drop on
	}
	else {
		if ([[[item representedObject] nodeTitle] isEqualToString:DEVICES_NAME]) {
			result = NSDragOperationNone;	// don't allow dragging into Devices group
		}
		else {
			if (index == -1) {
				result = NSDragOperationNone;	// don't allow dropping on a child
			}
			else {
				result = NSDragOperationMove;	// drop location is a container
			}
		}
	}
	return result;
}

//	The user is doing an intra-app drag within the outline view.
- (void)handleInternalDrops:(NSPasteboard*)pboard withIndexPath:(NSIndexPath*)indexPath {
	NSArray* newNodes = self.dragNodesArray;
	// move the items to their new place (we do this backwards, otherwise they will end up in reverse order)
	NSInteger i;
	for (i = ([newNodes count] - 1); i >=0; i--) {
		[treeController moveNode:[newNodes objectAtIndex:i] toIndexPath:indexPath];
	}
	// keep the moved nodes selected
	NSMutableArray* indexPathList = [NSMutableArray array];
	for (i = 0; i < [newNodes count]; i++) {
		[indexPathList addObject:[[newNodes objectAtIndex:i] indexPath]];
	}
	[treeController setSelectionIndexPaths: indexPathList];
	[self savePlaces];
}

//	This method is called when the mouse is released over an outline view that allows a drop
- (BOOL)outlineView:(NSOutlineView*)ov acceptDrop:(id <NSDraggingInfo>)info item:(id)targetItem childIndex:(NSInteger)index {
	// note that "targetItem" is a NSTreeNode proxy
	BOOL result = NO;
	if (targetItem) {
		NSIndexPath *indexPath = [[targetItem indexPath] indexPathByAddingIndex:index];	// find the index path to insert our dropped object
		NSPasteboard *pboard = [info draggingPasteboard];	// get the pasteboard
		if ([pboard availableTypeFromArray:[NSArray arrayWithObject:kNodesPBoardType]]) {
			[self handleInternalDrops:pboard withIndexPath:indexPath];	// intra-app drag within the outline view
			result = YES;
		}
	}
	return result;
}

@end
