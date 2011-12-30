//
//  ComparePanelController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 30/12/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "ComparePanelController.h"


@implementation ComparePanelController

- (id)init {
	if (self = [super initWithWindowNibName: @"ComparePanel"]) {
		[self window];
	}
	return self;
}

// Create a singleton instance of ComparePanelController to share, keeping Button states between uses
+ (ComparePanelController *)singleton {
    static ComparePanelController *instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
		[instance.dateNewer setState:YES];
		[instance.compareUnique setState:YES];
    }
    return instance;
}
- (IBAction)cancelCompare:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSCancelButton];
}
- (IBAction)performCompare:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSOKButton];
}
- (NSInteger)runModal {
	[self.destComboBox setObjectValue:[self.destComboBox objectValueOfSelectedItem]];
	NSInteger result = [NSApp runModalForWindow:self.window];
	return result;
}
- (void)setTitle:(NSString *)title {
	[self.window setTitle:title];
}
- (NSString *)targetDirectory {
	return [self.destComboBox stringValue];
}
- (void)setTargetDirs:(NSArray *)target {
	[self.destComboBox removeAllItems];
	[self.destComboBox addItemsWithObjectValues:target];
}
- (void)setSelectedDir:(NSInteger)n {
	if (n > [self.destComboBox numberOfItems] - 1)	{ n--; if(n) n--;}
	[self.destComboBox selectItemAtIndex:n];
}
- (void)setFrom:(NSString *)filename {
	[self.source setStringValue:filename];
}

@end
