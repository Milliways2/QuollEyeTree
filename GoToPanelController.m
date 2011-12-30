//
//  GoToPanelController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 12/04/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "GoToPanelController.h"
#import "IBPathTextField.h"

@implementation GoToPanelController

- (id)init {
	if (self = [super initWithWindowNibName: @"GoToPanel"]) { 
		[self window];
	}
	return self; 
}
- (IBAction)cancelGoTo:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSCancelButton];
}
- (IBAction)performGoTo:(id)sender {
    [path setStringValue:[[[path stringValue] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] stringByExpandingTildeInPath]];
    if([[NSFileManager defaultManager] fileExistsAtPath:self.directory]) {
        [self close];
        [NSApp stopModalWithCode:NSOKButton];
        return;
    }
    [notFound setHidden:NO];
}
- (NSInteger)runModal {
	NSInteger result = [NSApp runModalForWindow:self.window];
	return result;
}
- (NSString *)directory {
	return [path stringValue];	
}

@end
