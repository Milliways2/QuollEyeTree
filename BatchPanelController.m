//
//  BatchPanelController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 13/06/2015.
//
//

#import "BatchPanelController.h"
@implementation BatchPanelController

- (id)init {
	if (self = [super initWithWindowNibName: @"BatchPanel"]) {
		[self window];
	}
	[self.batchArgs setObjectValue:[[NSUserDefaults standardUserDefaults] stringForKey:PREF_BATCH_CMD]];
	return self;
}

- (IBAction)cancelBatch:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSCancelButton];
}
- (IBAction)performBatch:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSOKButton];
}
- (IBAction)editCmdSelected:(id)sender {
	[[NSUserDefaults standardUserDefaults]
	 setObject:[self.batchArgs stringValue]
	 forKey:PREF_BATCH_CMD];
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
	return [self.batchFileName stringValue];
}
- (void)setTargetDirs:(NSArray *)target {
	[self.destComboBox addItemsWithObjectValues:target];
}
- (void)setSelectedTarget:(NSInteger)n {
	[self.destComboBox selectItemAtIndex:n];
}

@end
