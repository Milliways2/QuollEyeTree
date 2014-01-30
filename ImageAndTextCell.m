/*
     File: ImageAndTextCell.m
 Abstract: Subclass of NSTextFieldCell which can display text and an image simultaneously.

  Version: 1.4
 */

#import "ImageAndTextCell.h"

#define kIconImageSize		16.0

#define kImageOriginXOffset 3
#define kImageOriginYOffset 1

#define kTextOriginXOffset	2
#define kTextOriginYOffset	0
#define kTextHeightAdjust	0

@implementation ImageAndTextCell

- (id)init {
	self = [super init];
	return self;
}

- (id)copyWithZone:(NSZone*)zone {
    ImageAndTextCell *cell = (ImageAndTextCell*)[super copyWithZone:zone];
    cell.image = self.image;
    return cell;
}

- (void)setImage:(NSImage*)anImage {
    if (anImage != _image) {
        _image = anImage;
		[_image setSize:NSMakeSize(kIconImageSize, kIconImageSize)];
    }
}

- (NSImage*)image {
    return _image;
}
- (NSRect)titleRectForBounds:(NSRect)cellRect {
	// the cell has an image: draw the normal item cell
	NSSize imageSize;
	NSRect imageFrame;

	imageSize = [self.image size];
	NSDivideRect(cellRect, &imageFrame, &cellRect, 3 + imageSize.width, NSMinXEdge);

	imageFrame.origin.x += kImageOriginXOffset;
	imageFrame.origin.y -= kImageOriginYOffset;
	imageFrame.size = imageSize;

	imageFrame.origin.y += ceil((cellRect.size.height - imageFrame.size.height) / 2);

	NSRect newFrame = cellRect;
	newFrame.origin.x += kTextOriginXOffset;
	newFrame.origin.y += kTextOriginYOffset;
	newFrame.size.height -= kTextHeightAdjust;

	return newFrame;
}

- (void)editWithFrame:(NSRect)aRect inView:(NSView*)controlView editor:(NSText*)textObj delegate:(id)anObject event:(NSEvent*)theEvent {
	NSRect textFrame = [self titleRectForBounds:aRect];
	[super editWithFrame:textFrame inView:controlView editor:textObj delegate:anObject event:theEvent];
}

- (void)selectWithFrame:(NSRect)aRect inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
	NSRect textFrame = [self titleRectForBounds:aRect];
	[super selectWithFrame:textFrame inView:controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSRect newCellFrame = cellFrame;
    if (self.image != nil) {
        NSSize	imageSize;
        NSRect	imageFrame;

        imageSize = [self.image size];
        NSDivideRect(newCellFrame, &imageFrame, &newCellFrame, imageSize.width, NSMinXEdge);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        imageFrame.origin.y += 1;
        imageFrame.size = imageSize;

        [self.image drawInRect:imageFrame
                      fromRect:NSZeroRect
                     operation:NSCompositeSourceOver
                      fraction:1.0
                respectFlipped:YES
                         hints:nil];
    }
    [super drawWithFrame:newCellFrame inView:controlView];
}
- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    cellSize.width += (self.image ? [self.image size].width : 0) + 3;
    return cellSize;
}

@end

