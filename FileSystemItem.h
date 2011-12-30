//
//  FileSystemItem.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 9/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface FileSystemItem: NSObject {
    NSString *relativePath;
    id __unsafe_unretained parent;
	NSImage *nodeIcon;
	NSString *kind;
@protected
	NSDate *cDate;
	NSDate *wDate;
}

@property (copy) NSString *relativePath;
@property (strong) NSImage *nodeIcon;   // bug fix for Xcode 4.4.1
@property (readonly) NSString *kind;
@property (copy) NSDate *cDate, *wDate;

- (id)parent;
- (void)setParent:(FileSystemItem *)newParent;
- (id)initWithPath:(NSURL *)path parent:(id)parentItem;
- (NSString *)fullPath;
- (NSURL *)url;

@end
