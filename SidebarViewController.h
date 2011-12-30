//
//  SidebarController.h
//  Sidebar
//
//  Created by Ian Binnie on 26/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SidebarViewControllerDelegate.h"
@class MyOutlineView;


@interface SidebarViewController : NSViewController {
	NSObject <SidebarViewControllerDelegate> *delegate;
	IBOutlet MyOutlineView		*myOutlineView;
	IBOutlet NSTreeController	*treeController;
	NSMutableArray				*sidebarContents;
	NSIndexPath	*devices;
	NSIndexPath	*places;
    FSEventStreamRef stream;
}

@property (strong) NSArray *dragNodesArray; // used to keep track of dragged nodes
@property NSObject <SidebarViewControllerDelegate> *delegate;

- (void)addPlace:(NSString *)path;

- (IBAction)removeEntry:(id)sender;
- (IBAction)openEntry:(id)sender;
- (IBAction)openEntryIntab:(id)sender;
- (IBAction)ejectVolume:(id)sender;

@end
