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
//@property (assign) IBOutlet NSObject <MyTextViewDelegate> *delegate;
@property (assign) IBOutlet id delegate;
- (NSRange)visibleRange;
@end
