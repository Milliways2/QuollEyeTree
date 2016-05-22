//
//  MyWindowController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 4/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "MyWindowController.h"
#import "MyWindowController+Refresh.h"
#import "TreeViewController.h"
#import "TreeViewController+Files.h"
#import "TreeViewController+Dirs.h"
#import "TreeViewController+Filter.h"
#import "FileItem.h"
#import "DirectoryItem.h"
#import "volume.h"
#import "SFDefaultTab.h"
#import "SidebarViewController.h"
#import "GoToPanelController.h"
#import "DeletedItems.h"
#import "PathHelper.h"
#import "IBDateFormatter.h"

NSString *NSStringFromBool (BOOL value) {
    return value ? @"YES" : @"NO";
}

static DirectoryItem *getDefaultDirectory() {
	return [[[systemRootVolume() volumeRoot] loadPath:[[[NSUserDefaults standardUserDefaults] stringForKey:PREF_DEFAULT_DIR] stringByResolvingSymlinksInPath]] logDir];
}

// FileItem will be used directly in preview panel and needs to implement the QLPreviewItem protocol
@interface FileItem(QLPreviewItem) <QLPreviewItem>
@end

@implementation FileItem(QLPreviewItem)
- (NSURL *)previewItemURL {
    return self.url;
}
@end

#pragma mark -
@interface MyWindowController()
- (void)selectDirectory:(NSString *)directory inTab:(BOOL)inTab;
@end

#pragma mark -
@implementation MyWindowController
@synthesize currentTvc, tabViewBar, sidebarDrawer;

NSOperationQueue *loggingQueue = nil;

- (BOOL)windowShouldClose:(id)sender {
    return [currentTvc shouldTerminate];   // Prevent Close Button if inappropriate
}
- (void)removeTabWithDirectory:(NSString *)directory  {
	NSArray *arrangedTabs = [tabViewBar arrangedTabs];

	NSIndexSet *tabsWithDirectory = [arrangedTabs indexesOfObjectsPassingTest:^(id tab, NSUInteger index, BOOL *stop) {
		TreeViewController *tvcInTab = [viewMap objectForKey:tab];
		if ([[[tvcInTab treeRootNode] fullPath] isEqualToString:directory]) return YES;	// directory is in tab
		return NO;
	}];

	// Need to ensure that we don't remove last tab
	NSMutableIndexSet *tabsToRemove = [NSMutableIndexSet new];
	[tabsToRemove addIndexes:tabsWithDirectory];
	if([tabsWithDirectory count] == [tabViewBar numberOfTabs]) {
		NSUInteger tabToKeep = [tabsWithDirectory firstIndex];
		[tabsToRemove removeIndex:tabToKeep];
		TreeViewController *tvcInTab = [viewMap objectForKey:[arrangedTabs objectAtIndex:tabToKeep]];
		[tvcInTab setTreeRootNode:getDefaultDirectory()];	// replace with default Directory
	}

	if([tabsToRemove count]) {
		NSUInteger index = [tabsToRemove lastIndex];
		while(index != NSNotFound) {
			[tabViewBar removeTab:[arrangedTabs objectAtIndex:index]];
			index = [tabsToRemove indexLessThanIndex:index];
		}
	}
}
- (void)removeTabsWithDeletedDirectories:(NSNotification *)notification {
	NSArray *directoriesRemoved = [notification.userInfo objectForKey:@"DirectoriesRemoved"];
	for (NSString *directory in directoriesRemoved) {
		[self removeTabWithDirectory: directory];
	}
}
- (void)goToPlace:(id)sender {
    NSString *place = [sender title];
    NSString *path = [[PathHelper sharedPathHelper] pathForName:place];
    [self selectDirectory:path inTab:NO];
}
- (void)setupGoMenu {
    PathHelper *pathHelper = [PathHelper sharedPathHelper];
    NSMenuItem *item;
    NSMenu *mainMenu = [self.window menu];
    NSImage *iconImage;
    NSArray *goPlaces;
    goPlaces = [NSArray arrayWithObjects:
                @"Documents",
                @"Desktop",
                @"Downloads",
                @"Home",
                @"Library",
                @"Computer",
                @"Applications",
                @"Utilities",
                nil];
    NSUInteger index = 0;
    for (NSString *place in goPlaces) {
        item = [goMenu insertItemWithTitle:[[NSFileManager defaultManager] displayNameAtPath:place] action:@selector(goToPlace:) keyEquivalent:@"" atIndex:index];
        [item setTarget:self];
        iconImage = [pathHelper iconForName:place];
        [iconImage setSize:NSMakeSize(16, 16)];
        [item setImage:iconImage];
        index++;
    }
    [mainMenu setSubmenu:goMenu forItem:[mainMenu itemAtIndex:3]];	// Initialise 'Go' Menu
}
- (TreeViewController *)newTreeViewControllerAtDir:(DirectoryItem *)userDir {
	[userDir logDir];	// log directory BEFORE creating controller
	TreeViewController *tvcNew = [[TreeViewController alloc]
								  initWithNibName:@"TreeView"
								  bundle:nil];
	tvcNew.delegate = self;
	[tvcNew initWithDir:userDir];
	return tvcNew;
}
- (void)changeSelection:(TreeViewController *)tvcNew {
    [[currentTvc view] removeFromSuperview];
	[currentTvc suspendTreeView];	// tell currentTvc to suspend processor intensive operations
    currentTvc = tvcNew;
	[self.viewContainer addSubview:[currentTvc view]];	// embed the TreeView in our host view
	[[currentTvc view] setFrame:[self.viewContainer bounds]];	// resize the controller's view to the host size
	[currentTvc activateTreeView];
	[currentTvc reloadData];	// there may have been changes to content in another tab
}
- (void)newTabWithDir:(DirectoryItem *)userDir {
	TreeViewController *tvcNew = [self newTreeViewControllerAtDir:userDir];
	[self changeSelection:tvcNew];
	[tabViewBar addTabWithRepresentedObject:[NSDictionary dictionaryWithObject:[tvcNew rootDirName] forKey:@"name"]];
}

+ (void)initialize {
	loggingQueue = [NSOperationQueue new];
	[loggingQueue setMaxConcurrentOperationCount:10];
}
// Initialise the 1st TreeViewController and display in main window
- (void)setupView {
	currentTvc = [self newTreeViewControllerAtDir:getDefaultDirectory()];
	[self.viewContainer addSubview:[currentTvc view]];	// embed the TreeView in our host view
	[[currentTvc view] setFrame:[self.viewContainer bounds]];	// resize the controller's view to the host size

	[currentTvc activateTreeView];
	[tabViewBar addTabWithRepresentedObject:[NSDictionary dictionaryWithObject:[currentTvc rootDirName] forKey:@"name"]];
}
- (id)initWithWindowNibName:(NSString *)windowNibName {
	if( self = [super initWithWindowNibName:windowNibName]) {
		// viewMap maintains a relationship between View and Tab (cannot use NSDictionary)
		viewMap = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory | NSMapTableObjectPointerPersonality
										valueOptions:NSMapTableStrongMemory | NSMapTableObjectPointerPersonality];
 		[self showWindow:self];
		tabViewBar.delegate = self;
		tabViewBar.tabOffset = -15;
		tabViewBar.startingOffset = 0;
		[self setupView];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(removeTabsWithDeletedDirectories:) name:DirectoryItemDidRemoveDirectoriesNotification object:nil];
		[self startMonitoring];
        [DeletedItems sharedDeletedItems].delegate = self;
        [self setupGoMenu];
        [[IBDateFormatter sharedDateFormatter] initialiseFormatters:[[NSUserDefaults standardUserDefaults]integerForKey:PREF_DATE_FORMAT]
                                                     showCreateTime:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_DATE_SHOW_CREATE]
                                                    useRelativeDate:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_DATE_RELATIVE]];
    }
	return self;
}

/*! @brief This method receives Automator Action QETNotification (sent by OpeninQuollEyeTree
 */
- (void)doAutomatorAction:(NSNotification *)notification {
    id dir = [[notification userInfo] valueForKey:@"Directory"];
    NSString *path = [dir objectAtIndex:0];
    [self selectDirectory:path inTab:YES];
}
- (void)timedUpdate:(NSTimer*)theTimer {
	[currentTvc refreshCounters];
}
- (void)awakeFromNib {
	sidebarController = [[SidebarViewController alloc]
						 initWithNibName:@"SidebarView"
						 bundle:nil];
	sidebarController.delegate = self;
	sidebarDrawer.contentView = sidebarController.view;
    NSURL *filter = [[NSBundle mainBundle] URLForResource:@"Filter" withExtension:@"png"];
    NSImage *image = [[NSImage alloc] initWithContentsOfURL:filter];
    [[[filterString cell] searchButtonCell] setImage:image];
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(doAutomatorAction:) name:QETNotification object:nil];
	[NSTimer scheduledTimerWithTimeInterval:3
									 target:self selector:@selector(timedUpdate:)
								   userInfo:nil repeats:YES];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    SEL action = [menuItem action];
    if (action == @selector(putBack:)) {
        NSMenu *putBackMenu = [[DeletedItems sharedDeletedItems] restoreMenu];
        if (putBackMenu) {
            [menuItem setSubmenu:putBackMenu];
            return YES;
        }
        return NO;
    }
    if (action == @selector(togglePreviewPanel:)) {
        if ([QLPreviewPanel sharedPreviewPanelExists] && [[QLPreviewPanel sharedPreviewPanel] isVisible]) {
            [menuItem setTitle:@"Close Quick Look panel"];
        } else {
            [menuItem setTitle:@"Open Quick Look panel"];
        }
        return YES;
    }
	if (action == @selector(pasteURL:)) {
		NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
		NSArray *classes = [[NSArray alloc] initWithObjects:[NSURL class], nil];
		NSDictionary *options = [NSDictionary dictionaryWithObject:
								 [NSNumber numberWithBool:YES] forKey:NSPasteboardURLReadingFileURLsOnlyKey];
		BOOL ok = [pasteboard canReadObjectForClasses:classes options:options];
		if (ok) {
			return YES;
        } else {
			return NO;
		}
	}
	if (action == @selector(toggleHidden:)) {
        DirectoryItem *currentDir = [currentTvc selectedDir];
        if([currentDir showHidden] && [currentDir showDotted])
            return NO;
        [menuItem setState:[currentDir showHidden] && ![currentDir showDotted] ? NSOnState : NSOffState];
        return YES;
	}
	if (action == @selector(toggleAllHidden:)) {
        DirectoryItem *currentDir = [currentTvc selectedDir];
        if([currentDir showHidden] && [currentDir showDotted])
            return NO;
        [menuItem setState:[currentDir showDotted] ? NSOnState : NSOffState];
        return YES;
	}
	if (action == @selector(goBack:)) {
        if(previousTvc)
            return YES;
        return NO;
	}
    return YES;
}

//- (void)openSidebar:(id)sender {[sidebarDrawer open];}
//- (void)closeSidebar:(id)sender {[sidebarDrawer close];}
- (void)toggleSidebar:(id)sender {
    NSDrawerState state = [sidebarDrawer state];
    if (NSDrawerOpeningState == state || NSDrawerOpenState == state) {
        [sidebarDrawer close];
    } else {
        [sidebarDrawer openOnEdge:NSMinXEdge];
    }
}

#pragma mark NSResponder Actions
- (void)keyDown:(NSEvent *)theEvent {
	unichar keyChar = [[theEvent characters] characterAtIndex:0];
    if (keyChar == 'f') {
        [filterString becomeFirstResponder];
        return;
    }
	[super keyDown:theEvent];
}

#pragma mark - QLPreviewPanelController Protocol
- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel {
    return YES;
}
- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel {
    previewPanel = panel;
    panel.delegate = self;
    panel.dataSource = self;
}
- (void)endPreviewPanelControl:(QLPreviewPanel *)panel {
    previewPanel = nil;
}

#pragma mark QLPreviewPanelDataSource Protocol
- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel {
    return [panelData count];
}
- (id <QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index {
    return [panelData objectAtIndex:index];
}

#pragma mark DeletedItemsDelegate Delegate Methods
- (void)updateDirectory:(NSString *)path {
    DirectoryItem *targetDir = findPathInVolumes(path);
    if (targetDir) {
        if ([targetDir isPathLoaded]) {
            [targetDir updateDirectory];	// Update target directory if loaded.
            [currentTvc reloadData];
        }
    }
}

#pragma mark - TreeViewControllerDelegate Protocol
- (void)treeViewController:(TreeViewController *)tv setPanelData:(NSArray *)array {
    if (array != panelData) {
        array = [array copy];
        panelData = array;
        [previewPanel reloadData];
    }
}
- (void)treeViewController:(TreeViewController *)tvc tabState:(BOOL)state {
	[showTagged setState:state];
}
- (void)treeViewController:(TreeViewController *)tvc filterValue: (NSString *)string  {
	[filterString setStringValue:string];
}
- (void)treeviewDidEnterFileWindow:(TreeViewController *)tvc {
	NSMenu *mainMenu = [self.window menu];
	[mainMenu setSubmenu:fileMenu forItem:[mainMenu itemAtIndex:1]];	// Initialise 'File' Menu
}
- (void)treeviewDidEnterDirWindow:(TreeViewController *)tvc {
	NSMenu *mainMenu = [self.window menu];
	[mainMenu setSubmenu:dirMenu forItem:[mainMenu itemAtIndex:1]]; // Initialise 'Dir' Menu
}
- (void)treeViewController:(TreeViewController *)tvc rootChangedInTreeView:(NSString *)rootDirName {
	for(id key in viewMap){
		if ([[viewMap objectForKey:key] isEqual:tvc]) {
			[(SFDefaultTab *)key setRepresentedObject:[NSDictionary dictionaryWithObject:rootDirName forKey:@"name"]];
		}
	}
}
- (TreeViewController *)treeViewController:(TreeViewController *)tvc addNewTabAtDir:(DirectoryItem *)dir {
	[self addNewTab:self];
	[currentTvc setTreeRootNode:dir];
	return currentTvc;
}
- (void)treeViewController:(TreeViewController *)tvc addToSidebar:(NSString *)directory {
	[sidebarController addPlace:directory];
}
- (void)treeViewController:(TreeViewController *)tvc didRemoveDirectory:(NSString *)directory {
	[self removeTabWithDirectory:directory];
}
- (void)treeViewController:(TreeViewController *)tvc pauseRefresh:(BOOL)pause {
	[self pauseMonitoring:pause];
}

#pragma mark -
// Returns an array TreeViewControllers corresponding to Tabs
- (NSArray *)tvcInTabs {
	int numberOfTabs = [tabViewBar numberOfTabs];
	NSArray *arrangedTabs = [tabViewBar arrangedTabs];
	NSMutableArray *tvcArray = [NSMutableArray arrayWithCapacity:numberOfTabs];
	for (int j=0; j<numberOfTabs; ++j) {
		[tvcArray addObject:[viewMap objectForKey:[arrangedTabs objectAtIndex:j]]];
	}
	return tvcArray;
}
- (TreeViewController *)tvcAtIndex:(NSInteger)index {
	return [viewMap objectForKey:[tabViewBar tabAtIndex:index]];
}
- (NSInteger)currentTab {
	return [tabViewBar indexOfTab:[tabViewBar selectedTab]];
}
- (void)selectDirectory:(NSString *)directory inTab:(BOOL)inTab {
	DirectoryItem *userDir = locateOrAddDirectoryInVolumes(directory);
    if (userDir) {
		if (inTab)  [self newTabWithDir:userDir];
		else    [currentTvc setTreeRootNode:userDir];
// Following removed 2014-10-08 (problem with Go Back)
//		else {	// create new TreeViewController with directory and replace in view
//			previousTvc = currentTvc;
////			TreeViewController *tvcNew = [self newTreeViewControllerAtDir:userDir];
////			[self changeSelection:tvcNew];	// replace TVC in view
//			[self changeSelection:[self newTreeViewControllerAtDir:userDir]];	// replace TVC in view
//			[(SFDefaultTab *)[tabViewBar selectedTab] setRepresentedObject:[NSDictionary dictionaryWithObject:[userDir relativePath] forKey:@"name"]];
//		}
    }
}
#pragma mark SidebarViewController Delegate Methods
- (void)sidebarViewController:(SidebarViewController *)svc shouldSelectDirectory:(NSString *)directory inTab:(BOOL)inTab {
    [self selectDirectory:directory inTab:inTab];
}
- (void)sidebarViewController:(SidebarViewController *)svc shouldRemoveVolume:(NSString *)directory {
    VolumeItem *volume = locateVolume(directory);
    if (volume) {
        NSArray *arrangedTabs = [tabViewBar arrangedTabs];	// Volume is loaded so check tabs

        NSIndexSet *tabsWithVolume = [arrangedTabs indexesOfObjectsPassingTest:^(id tab, NSUInteger index, BOOL *stop) {
            TreeViewController *tvcInTab = [viewMap objectForKey:tab];
            id rootDir = [[tvcInTab selectedDir] rootDir];
            id parent = [rootDir parent];
            if (parent == nil) return NO;	// should never be nil
            if ([parent isKindOfClass:[VolumeItem class]]) {
                if ([[parent volumePath] isEqualToString:directory]) return YES;	// Volume is in tab
            }
            return NO;
        }];

        // Need to ensure that we don't remove last tab
        NSMutableIndexSet *tabsToRemove = [NSMutableIndexSet new];
        [tabsToRemove addIndexes:tabsWithVolume];
        if([tabsWithVolume count] == [tabViewBar numberOfTabs]) {
            NSUInteger tabToKeep = [tabsWithVolume firstIndex];
            [tabsToRemove removeIndex:tabToKeep];
            TreeViewController *tvcInTab = [viewMap objectForKey:[arrangedTabs objectAtIndex:tabToKeep]];
            [tvcInTab setTreeRootNode:getDefaultDirectory()];	// replace with default Directory
        }

        if([tabsToRemove count]) {
            NSUInteger index = [tabsToRemove lastIndex];
            while(index != NSNotFound) {
                [tabViewBar removeTab:[arrangedTabs objectAtIndex:index]];
                index = [tabsToRemove indexLessThanIndex:index];
            }
        }
        removeVolume(volume);	// Now remove volume
    }
}
- (IBAction)privateTest:(id)sender {
	NSLog(@"privateTest");
	NSLog(@"Map Entries %lu", (unsigned long)NSCountMapTable(viewMap));
//	[self sidebarViewController:sidebarController shouldRemoveVolume:@"/Volumes/TSB USB DRV"];
}
- (IBAction)toggleMark:(id)sender {
    NSInteger noSearches = [[filterString recentSearches] count];
    NSMutableArray *searches = [NSMutableArray arrayWithCapacity:noSearches];
    [searches setArray:[filterString recentSearches]];
    NSString *topSearch = [searches objectAtIndex:0];
    NSString *newTopSearch;
    NSRange markedRange = [topSearch rangeOfString:marked options:NSAnchoredSearch];
    if (markedRange.length)
        newTopSearch = [topSearch substringFromIndex:markedRange.length];
    else
        newTopSearch = [marked stringByAppendingString:topSearch];
    NSUInteger found = [searches indexOfObject:newTopSearch];
    if (found != NSNotFound)
        [searches removeObjectAtIndex:found];
    [searches replaceObjectAtIndex:0 withObject:newTopSearch];
    [filterString setRecentSearches:searches];
    [filterString setStringValue:newTopSearch];
}
- (IBAction)currentFileFilter:(id)sender {
    [filterString setStringValue:[currentTvc getTargetFile]];
}
#pragma mark NSControl Delegate Methods
//	The text in NSSearchField has changed; clear filter if Cancel pressed
- (void)controlTextDidChange:(NSNotification *)notification {
	NSString* searchString = [[notification object] stringValue];
	if([searchString length] == 0) {
		[currentTvc applyFileFilter:searchString];
	}
}
- (void)controlTextDidEndEditing:(NSNotification *)notification {
    NSSearchField *object = [notification object];
	NSString *searchString = [object stringValue];
    NSInteger noSearches = [[object recentSearches] count];
    NSMutableArray *searches = [NSMutableArray arrayWithCapacity:noSearches];
    [searches setArray:[object recentSearches]];
    NSRange markedRange = [searchString rangeOfString:marked options:NSAnchoredSearch];
    if (markedRange.length == 0) {
        NSString *newTopSearch = [marked stringByAppendingString:searchString];
        NSUInteger found = [searches indexOfObject:newTopSearch];
        if (found != NSNotFound && found > 0) {
            [searches exchangeObjectAtIndex:0 withObjectAtIndex:found]; // put marked search on top
            [searches removeObjectAtIndex:found];
            [filterString setRecentSearches:searches];
            [filterString setStringValue:newTopSearch];
        }
    }
    noSearches = [searches count];
    NSInteger maximumRecents = [[object cell] maximumRecents];
    if (noSearches >= maximumRecents) {
        for (NSInteger i=noSearches-1; i; i--) {
            if ([[searches objectAtIndex:i] characterAtIndex:0] != diamond) {
                [searches removeObjectAtIndex:i];
                [filterString setRecentSearches:searches];
                break;
            }
        }
    }
	[currentTvc applyFileFilter:searchString];
}

#pragma mark - SFTabView Delegate Methods
- (void)tabView:(SFTabView *)tabView didAddTab:(CALayer *)tab {
	[tabView selectTab:tab];
	[viewMap setObject:currentTvc forKey:tab];
}
- (BOOL)tabView:(SFTabView *)tabView shouldRemoveTab:(CALayer *)tab {
	if([tabViewBar numberOfTabs] == 1)  return NO; // Need to ensure that we don't remove last tab
    return YES;
}
- (void)tabView:(SFTabView *)tabView didRemoveTab:(CALayer *)tab {
	[viewMap removeObjectForKey:tab];	// remove Tab from list
}
- (BOOL)tabView:(SFTabView *)tabView shouldSelectTab:(CALayer *)tab {
    return YES;
}
- (void)tabView:(SFTabView *)tabView didSelectTab:(CALayer *)tab {
	TreeViewController *tvcSelected = [viewMap objectForKey:tab];
	if (tvcSelected)
		if (tvcSelected != currentTvc)
			[self changeSelection:tvcSelected];
}
- (void)tabView:(SFTabView *)tabView willSelectTab:(CALayer *)tab {}

#pragma mark Toolbar Button Actions
- (IBAction)segControlClicked:(id)sender {
	[currentTvc segControlClicked:sender];
}
- (IBAction)togglePreviewPanel:(id)sender {
	[currentTvc togglePreviewPanel];
}
- (IBAction)toggleShowTagged:(id)sender {
	[currentTvc toggleShowTagged];
}

#pragma mark Menu Actions
- (IBAction)removeThisTab: (id)sender {
	if([tabViewBar numberOfTabs] == 1)  return; // Need to ensure that we don't remove last tab
	CALayer *currentTab = [tabViewBar selectedTab];
	[tabViewBar selectPreviousTab:self];
	[self changeSelection:[viewMap objectForKey:[tabViewBar selectedTab]]];
	[tabViewBar removeTab:currentTab];
}
- (IBAction)addNewTab:(id)sender {
	[self newTabWithDir:getDefaultDirectory()];
}
- (IBAction)addNewTabAt:(id)sender {
	[self newTabWithDir:[currentTvc selectedDir]];
}
- (IBAction)toggleView:(id)sender {
//	NSLog(@"toggleView");
	[currentTvc toggleView];
}
- (IBAction)gotoDir:(id)sender {
	GoToPanelController *gotoPanel = [GoToPanelController new];
	if ([gotoPanel runModal] == NSOKButton) {
//	if ([gotoPanel runModal] == NSModalResponseOK) {
		NSString *newDir = [[gotoPanel directory] stringByExpandingTildeInPath];
        [self selectDirectory:newDir inTab:NO];
    }
}
- (IBAction)goBack:(id)sender {
	if(previousTvc) {
		[self changeSelection:previousTvc];	// replace TVC in view
		[(SFDefaultTab *)[tabViewBar selectedTab] setRepresentedObject:[NSDictionary dictionaryWithObject:[previousTvc.selectedDir relativePath] forKey:@"name"]];
		previousTvc = nil;
	}
}

@end
