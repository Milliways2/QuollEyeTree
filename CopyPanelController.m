//
//  CopyPanelController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 14/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "CopyPanelController.h"


@implementation CopyPanelController

- (id)init {
	if (self = [super initWithWindowNibName: @"CopyMovePanel"]) { 
		[self window];
	}
	return self; 
}
- (IBAction)cancelCopy:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSCancelButton];
}
- (IBAction)performCopy:(id)sender {
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
- (NSString *)filename {
	return [self.name stringValue];	
}
- (void)setTargetDirs:(NSArray *)target {
	[self.destComboBox addItemsWithObjectValues:target];
}
- (void)setSelectedDir:(NSInteger)n {
	[self.destComboBox selectItemAtIndex:n];
}
- (void)setFilename:(NSString *)filename {
	[self.name setStringValue:filename];
}
- (void)setFrom:(NSString *)filename {
	[self.source setStringValue:filename];
}

@end
