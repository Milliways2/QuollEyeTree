//
//  VolumeItem.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 30/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class DirectoryItem;

@interface VolumeItem : NSObject {
}

@property (strong) DirectoryItem *volumeRoot;
@property (copy) NSString *relativePath;
@property (strong) id parent;

- (NSString *)fullPath;
- (NSString *)volumePath;
- (NSString *)localPath:(NSString *)path;

@end
