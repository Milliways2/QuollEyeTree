//
//  volume.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 15/08/12.
//
//
#import "VolumeItem.h"

extern void initializeVolumes();
extern VolumeItem *systemRootVolume();
extern VolumeItem *addVolume(NSString *volumePath);
extern void removeVolume(VolumeItem *volume);
extern VolumeItem *locateVolume(NSString *volumePath);
extern VolumeItem *locateOrAddVolume(NSString *volumePath);
DirectoryItem *findPathInVolumes(NSString *path);
