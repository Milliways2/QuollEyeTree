//
//  MyOutlineView.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 18/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol MyOutlineViewDelegate
@optional
- (BOOL)keyPressedInOutlineView:(unichar)character shifted:(BOOL)shifted;
- (BOOL)keyCmdPressedInOutlineView:(unichar)character;
- (BOOL)keyCtlPressedInOutlineView:(unichar)character;
- (void)mouseDownInOutlineView;
- (void)validateContextMenu:(NSMenu *)menu;
@end

@interface MyOutlineView: NSOutlineView {
}

@property (assign) IBOutlet NSObject <MyOutlineViewDelegate> *keyDelegate;
@property (strong) id focusedItem;

@end
