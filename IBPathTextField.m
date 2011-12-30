//
//  IBPathField.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 16/04/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "IBPathTextField.h"

@implementation IBPathTextField
- (void)awakeFromNib {
    [self setDelegate:self];
}

//	Override NSFieldEditor's default matches
- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words
 forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index {
	return possibleMatches;
}
// Intercept tab inserts and autocomplete
- (BOOL)control:(NSControl *)control textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
	BOOL result = NO;    
    if (aSelector == @selector(insertTab:)) {
        possibleMatches = NULL;
		NSRange selectedRange = [aTextView selectedRange];
		// only autocomplete if no selection & insertion point is at the end
		if (selectedRange.length == 0 && selectedRange.location == [[control stringValue] length]) {
            NSString *autocompletedPath = NULL;
            NSArray *outputArray;
            NSUInteger noMatches = [[[control stringValue] stringByExpandingTildeInPath] completePathIntoString:&autocompletedPath caseSensitive:YES matchesIntoArray:&outputArray filterTypes:NULL];
            if (noMatches > 1) {
                possibleMatches = [NSMutableArray arrayWithCapacity:noMatches];
                for (NSString *item in outputArray) {
                    [possibleMatches addObject:[item lastPathComponent]];
                }
            }
            [control setStringValue:autocompletedPath];
            result = YES;
        }
    }
    return result;
}

@end
