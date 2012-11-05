//
//  MyTextView.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 6/07/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol MyTextViewDelegate
- (BOOL)keyPressedInTextView:(NSEvent *)theEvent;
@end

@interface MyTextView : NSTextView
@property (strong) IBOutlet NSObject <MyTextViewDelegate> *delegate;
- (NSRange)visibleRange;
@end
