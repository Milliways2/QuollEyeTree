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

/*! @brief This property contains the DirectoryItem which is the root directory of the Volume
 */
@property (strong) DirectoryItem *volumeRoot;
@property (copy) NSString *relativePath;
@property (assign) id parent;

- (NSString *)fullPath;
/*! @brief An NSString object containing the full path to this Volume e.g. path with leading /Volumes/VOLUME_NAME  or /
 */
- (NSString *)volumePath;
/*!	@brief	local path i.e. path with /Volumes stripped
 @discussion	This is the path relative to the root of the volume
 @param	path A string object containing an absolute path
 @return	An NSString object containing the local path with /Volumes stripped
*/
- (NSString *)relativePathOnVolume:(NSString *)path;

@end
