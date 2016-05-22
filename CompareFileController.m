//
//  CompareFileController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 2/12/12.
//
//

#import "CompareFileController.h"

@implementation CompareFileController

- (id)init {
	if (self = [super initWithWindowNibName: @"CompareFilePanel"]) {
		[self window];
	}
	return self;
}
- (IBAction)cancelCompare:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSCancelButton];
}
- (IBAction)performCompare:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSOKButton];
}

- (IBAction)targetDirSelected:(id)sender {
	NSInteger index = [sender indexOfSelectedItem];
	if (index >= 0) {
		[self.delegate compareFileController:self didSelectTabAtIndex:index];
	}
}
- (NSInteger)runModal {
	[self.destComboBox setObjectValue:[self.destComboBox objectValueOfSelectedItem]];
	NSInteger result = [NSApp runModalForWindow:self.window];
	return result;
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
- (void)setSelectedTarget:(NSInteger)n {
	[self.destComboBox selectItemAtIndex:n];
}
- (void)setTargetNames:(NSArray *)target {
	[self.name removeAllItems];
	[self.name addItemsWithObjectValues:target];
}
- (void)setSelectedName:(NSInteger)n {
	[self.name selectItemAtIndex:n];
}
- (void)setFilename:(NSString *)filename {
	[self.name setStringValue:filename];
}
- (void)setFrom:(NSString *)filename {
	[self.source setStringValue:filename];
}

@end
