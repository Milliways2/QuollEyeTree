/*
     File: ImageAndTextCell.h 
 Abstract: Subclass of NSTextFieldCell which can display text and an image simultaneously.
  
  Version: 1.4 
  
  
 */

#import <Cocoa/Cocoa.h>

@interface ImageAndTextCell: NSTextFieldCell {
	NSImage *_image;
}

@property (readwrite, strong) NSImage *image;
@end
