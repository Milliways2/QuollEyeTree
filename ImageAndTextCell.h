/*
     File: ImageAndTextCell.h 
 Abstract: Subclass of NSTextFieldCell which can display text and an image simultaneously.
  
  Version: 1.3 
  
  
 */

#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell: NSTextFieldCell {
	NSImage *image;
}

@property (readwrite, strong) NSImage *image;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (NSSize)cellSize;

@end
