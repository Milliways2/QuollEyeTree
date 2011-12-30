//
//  MyTextView.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 6/07/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "TextViewerView.h"

@implementation TextViewerView

- (void)keyDown:(NSEvent *)theEvent {
    if([self.delegate respondsToSelector:@selector(keyPressedInTextView:)]) {
        if([self.delegate keyPressedInTextView:theEvent])
            return;
    }
	[super keyDown:theEvent];
}

@end
