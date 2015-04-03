//
//  VolumeItem.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 30/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "VolumeItem.h"
#import "DirectoryItem.h"

@implementation VolumeItem
- init {
	if (self = [super init]) {
		self.parent = nil;
		self.relativePath = @"";
	}
	return self;
}
// this method is only to enable DirectoryItem fullPath completion (it overrides DirectoryItem fullPath)
- (NSString *)fullPath {
	return self.relativePath;
}
- (NSString *)volumePath {
	return [self.volumeRoot fullPath];
}
- (NSString *)relativePathOnVolume:(NSString *)path {
	NSRange range = [path rangeOfString:self.relativePath];
	if (range.length)
		return [path substringFromIndex:range.length+1];
	return path;
}
@end
