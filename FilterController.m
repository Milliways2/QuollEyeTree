//
//  FilterController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 27/12/12.
//
//

#import "FilterController.h"

@interface FilterController ()

@end

@implementation FilterController

- (id)init {
	if (self = [super initWithWindowNibName: @"FilterController"]) {
		[self window];
	}
	return self;
}
- (IBAction)performFilter:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSOKButton];
}

- (IBAction)cancelFilter:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSCancelButton];
}

- (NSInteger)runModal {
//	[self.destComboBox setObjectValue:[self.destComboBox objectValueOfSelectedItem]];
	NSInteger result = [NSApp runModalForWindow:self.window];
	return result;
}


@end
