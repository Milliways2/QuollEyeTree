//
//  FileSystemItem.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 9/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "FileSystemItem.h"

@implementation FileSystemItem
@synthesize relativePath, kind;
@synthesize nodeIcon, alias, package, cDate, wDate;

- (id)initWithPath:(NSURL *)path parent:(id)parentItem {
	if(self = [super init]) {
		relativePath = [[path lastPathComponent] copy];
		NSDate *tempDate;
		[path getResourceValue:&tempDate forKey:NSURLCreationDateKey error:nil];
        if ([tempDate timeIntervalSince1970] < 24*3600) tempDate = nil;
		cDate = [tempDate copy];
		[path getResourceValue:&tempDate forKey:NSURLContentModificationDateKey error:nil];
		wDate = [tempDate copy];
		parent = parentItem;
        NSString *tempKind;
		[path getResourceValue:&tempKind forKey:NSURLLocalizedTypeDescriptionKey error:nil];
        kind = tempKind;
		id value = nil;
		[path getResourceValue:&value forKey:NSURLIsAliasFileKey error:nil];
		alias = [value boolValue];
		[path getResourceValue:&value forKey:NSURLIsPackageKey error:nil];
		package = [value boolValue];
	}
    return self;
}
- (FileSystemItem *)parent {
    if (parent == nil) {
        return self;	// If no parent, return self
    }
	return parent;
}
- (void)setParent:(FileSystemItem *)newParent {
	parent = newParent;
}

- (NSString *)fullPath {
    if (parent == nil) {
        return relativePath;    // If no parent, return our own relative path
    }
    // recurse up the hierarchy, prepending each parent’s path
    return [[parent fullPath] stringByAppendingPathComponent:relativePath];
}

- (NSURL *)url {
    return [NSURL fileURLWithPath:self.fullPath];
}

@end
