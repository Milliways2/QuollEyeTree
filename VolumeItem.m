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
// this method is only to enable DirectoryItem fullPath completion
- (NSString *)fullPath {
	return self.relativePath;
}
// Returns path to this Volume e.g. path with /Volumes/VOLUME_NAME or /
- (NSString *)volumePath {
	return [self.volumeRoot fullPath];
}
// Returns local path i.e. path with /Volumes stripped
- (NSString *)localPath:(NSString *)path {
	NSRange range = [path rangeOfString:self.relativePath];
	if (range.length)
		return [path substringFromIndex:range.length+1];
	return path;
}
@end
