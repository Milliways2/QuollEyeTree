//
//  MyTextView.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 6/07/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol TextViewerViewDelegate
- (BOOL)keyPressedInTextView:(NSEvent *)theEvent;
@end

@interface TextViewerView : NSView
@property (strong) IBOutlet NSObject <TextViewerViewDelegate> *delegate;

@end
