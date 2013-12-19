//
//  MyOutlineView.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 18/07/11.
//  Copyright 20111-2013 Ian Binnie. All rights reserved.
//

#import "MyOutlineView.h"

@implementation MyOutlineView
- (id)validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType {
	if([self.keyDelegate respondsToSelector:@selector(validRequestorForSendType:returnType:)])
        return [self.keyDelegate validRequestorForSendType:sendType returnType:returnType];
    return [super validRequestorForSendType:sendType returnType:returnType];
}
- (void)keyDown:(NSEvent *)theEvent {
	unichar keyChar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	if ([theEvent modifierFlags] & NSCommandKeyMask) {
		if([self.keyDelegate respondsToSelector:@selector(keyCmdPressedInOutlineView:)])
			if([self.keyDelegate keyCmdPressedInOutlineView:keyChar])
				return;
	}
	if ([theEvent modifierFlags] & NSControlKeyMask) {
		if([self.keyDelegate respondsToSelector:@selector(keyCtlPressedInOutlineView:)])
			if([self.keyDelegate keyCtlPressedInOutlineView:keyChar])
				return;
	}
	if([self.keyDelegate respondsToSelector:@selector(keyPressedInOutlineView:shifted:)])
		if([self.keyDelegate keyPressedInOutlineView:keyChar shifted:([theEvent modifierFlags] & NSShiftKeyMask)==NSShiftKeyMask])
			return;
	[super keyDown:theEvent];
}
- (void)mouseDown:(NSEvent *)theEvent {
	if([self.keyDelegate respondsToSelector:@selector(mouseDownInOutlineView)])
		[self.keyDelegate mouseDownInOutlineView];
	[super mouseDown:theEvent];
}
- (NSMenu *)menuForEvent:(NSEvent *)theEvent {
	NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	self.focusedItem = [self itemAtRow: [self rowAtPoint:pt]];
	NSMenu *menu = [self menu];
	if([self.keyDelegate respondsToSelector:@selector(validateContextMenu:)])
		[self.keyDelegate validateContextMenu:menu];
	return menu;
}

@end
