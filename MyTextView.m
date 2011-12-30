//
//  MyTextView.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 6/07/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "MyTextView.h"

@implementation MyTextView
@synthesize delegate;

- (void)keyDown:(NSEvent *)theEvent {
    if([self.delegate respondsToSelector:@selector(keyPressedInTextView:)]) {
        if([self.delegate keyPressedInTextView:theEvent])
            return;
        }
	[super keyDown:theEvent];
}
- (NSRange)visibleRange {
    NSRect visibleRect = [self visibleRect];
    NSLayoutManager *lm = [self layoutManager];
    NSTextContainer *tc = [self textContainer];
    NSRange glyphVisibleRange = [lm glyphRangeForBoundingRect:visibleRect inTextContainer:tc];;
    NSRange charVisibleRange = [lm characterRangeForGlyphRange:glyphVisibleRange  actualGlyphRange:nil];
    return charVisibleRange;
} 
@end
