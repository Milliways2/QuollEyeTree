//
//  volume.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 15/08/12.
//
//
/*!
 @header	volume.h

 @brief	This is the header file containing supporting functions for managing Volumes.
 @discussion	This contains an Array of volumes, contains at least "/"
 */

#import "VolumeItem.h"

extern void initializeVolumes();
/*!	@return	A VolumeItem object of the system root "/"
 */
extern VolumeItem *systemRootVolume();
extern void removeVolume(VolumeItem *volume);
/*!	@return	A VolumeItem object of the Volume Path or nil
 */
extern VolumeItem *locateVolume(NSString *volumePath);
/*! @brief Search all logged volumes for directory
 @return	A DirectoryItem object
 */
DirectoryItem *findPathInVolumes(NSString *directory);
/*! @brief locate directory in logged volumes, loading if necessary
 @return	A DirectoryItem object
 */
DirectoryItem *locateOrAddDirectoryInVolumes(NSString *directory);
