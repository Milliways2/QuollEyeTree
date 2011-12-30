//
//  SearchPanelController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 13/06/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "SearchPanelController.h"

@implementation SearchPanelController
- (id)init {
	if (self = [super initWithWindowNibName: @"SearchPanel"]) { 
		[self window];
	}
	return self; 
}
// Create a singleton instance of SearchPanelController to share, keeping Button states between uses
+ (SearchPanelController *)singleton {
    static SearchPanelController *instance = nil;
    if (instance == nil) {
        instance = [[self alloc] init];
    }
    [instance.regex setHidden:NO];
    return instance;
}
- (IBAction)cancelSearch:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSCancelButton];
}
- (IBAction)performSearch:(id)sender {
	[self close];
	[NSApp stopModalWithCode:NSOKButton];
}
- (NSInteger)runModal {
	NSInteger result = [NSApp runModalForWindow:self.window];
	return result;
}
- (NSString *)searchString {
	return [self.searchFor stringValue];
}
- (BOOL)isCaseSensitive {
    return [self.caseSensitive state];
}
- (BOOL)regexSearch {
    return regexPermitted && ([self.regex selectedRow] > 0);
}
char regexType[] = {'F', 'G', 'E', 'P'};
- (NSString *)searchArguments {
    return [NSString stringWithFormat:@"-qs%c%@", regexType[[self.regex selectedRow]], [self isCaseSensitive] ? @"" : @"i"];
}
- (void)allowRegex:(BOOL)reg {
    regexPermitted = reg;
    [self.regex setHidden:!reg];
}
@end
