//
//  myTableView.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 18/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "MyTableView.h"

@implementation MyTableView
- (void)copy:(id)sender {
    if([self.keyDelegate respondsToSelector:@selector(copyFile:)])
        [self.keyDelegate copyFile:sender];
}

- (void)keyDown:(NSEvent *)theEvent {
	unichar keyChar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	if ([theEvent modifierFlags] & NSCommandKeyMask) {
		if([self.keyDelegate respondsToSelector:@selector(keyCmdPressedInTableView:)])
			if([self.keyDelegate keyCmdPressedInTableView:keyChar])
				return;
	}
	if ([theEvent modifierFlags] & NSControlKeyMask) {
		if([self.keyDelegate respondsToSelector:@selector(keyCtlPressedInTableView:)])
			if([self.keyDelegate keyCtlPressedInTableView:keyChar])
				return;
	}
	if ([theEvent modifierFlags] & NSAlternateKeyMask) {
		if([self.keyDelegate respondsToSelector:@selector(keyAltPressedInTableView:)])
			if([self.keyDelegate keyAltPressedInTableView:keyChar])
				return;
	}
	if([self.keyDelegate respondsToSelector:@selector(keyPressedInTableView:)])
		if([self.keyDelegate keyPressedInTableView:keyChar])
			return;
	[super keyDown:theEvent];
}
- (void)mouseDown:(NSEvent *)theEvent {
	if([self.keyDelegate respondsToSelector:@selector(mouseDownInTableView)])
		[self.keyDelegate mouseDownInTableView];
	[super mouseDown:theEvent];
}
- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSMenu *theMenu = [self menu];
	if([self.keyDelegate respondsToSelector:@selector(validateTableContextMenu:)])
		[self.keyDelegate validateTableContextMenu:theMenu];
    return theMenu;
}

@end
