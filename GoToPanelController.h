//
//  GoToPanelController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 12/04/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class IBPathTextField;

@interface GoToPanelController : NSWindowController {
    IBOutlet IBPathTextField *path;
    IBOutlet NSTextField *notFound;
}

- (IBAction)cancelGoTo:(id)sender;
- (IBAction)performGoTo:(id)sender;

- (NSInteger)runModal;
- (NSString *)directory;

@end
