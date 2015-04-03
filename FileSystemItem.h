//
//  FileSystemItem.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 9/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/*! @class FileSystemItem

 @brief The FileSystemItem class

 @discussion    This is a base class containing common properties/methods to support Files and Directories.
 @classdesign	This class should only be used when no distinction is needed betweeen Files and Directories.
 */
@interface FileSystemItem: NSObject {
    NSString *relativePath;
    id __unsafe_unretained parent;
	NSImage *nodeIcon;
	NSString *kind;
@protected
	BOOL alias;
	BOOL package;
	NSDate *cDate;
	NSDate *wDate;
}

@property (copy) NSString *relativePath;
@property (strong) NSImage *nodeIcon;   // bug fix for Xcode 4.4.1
@property (readonly) NSString *kind;
@property (copy) NSDate *cDate, *wDate;
@property (readonly, getter=isAlias) BOOL alias;
@property (readonly, getter=isPackage) BOOL package;

- (id)parent;
- (void)setParent:(FileSystemItem *)newParent;
- (id)initWithPath:(NSURL *)path parent:(id)parentItem;
- (NSString *)fullPath;
- (NSURL *)url;

@end
