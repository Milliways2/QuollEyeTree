//
//  RenamePanelController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 14/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface RenamePanelController : NSWindowController {
	IBOutlet NSTextField *source, *name;
}

- (IBAction)cancelRename:(id)sender;
- (IBAction)performRename:(id)sender;

- (NSInteger)runModal;
- (void)setTitle:(NSString *)title;
- (void)setFrom:(NSString *)filename;
- (NSString *)filename;
- (void)setFilename:(NSString *)filename;

@end
