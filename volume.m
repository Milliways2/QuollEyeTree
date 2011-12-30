//
//  volume.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 15/08/12.
//
//
#import "DirectoryItem.h"
#import "VolumeItem.h"

static NSMutableArray *volumes = nil;   // Array of volumes, contains at least "/"

void initializeVolumes() {
	VolumeItem *mainRoot = [VolumeItem new];	// create VolumeItem for FileSystem Root
	mainRoot.volumeRoot = [[DirectoryItem alloc] initRootWithPath:[NSURL fileURLWithPath:@"/"]];
	volumes = [NSMutableArray new];
	[volumes addObject:mainRoot];
}
VolumeItem *systemRootVolume() {
    return [volumes objectAtIndex:0];
}
VolumeItem *addVolume(NSString *volumePath) {
	VolumeItem * newVolume = [VolumeItem new];	// Add new Volume
	newVolume.relativePath = [volumePath stringByDeletingLastPathComponent];
	newVolume.volumeRoot = [[DirectoryItem alloc] initWithPath:[NSURL fileURLWithPath:volumePath] parent:newVolume];
	[volumes addObject:newVolume];
	return newVolume;
}
void removeVolume(VolumeItem *volume) {
    [volumes removeObject:volume];	// Now remove from volumes
}
VolumeItem *locateVolume(NSString *volumePath) {
    for (VolumeItem *volume in volumes) {
        if ([[volume volumePath] isEqualToString:volumePath])    return volume;
    }
    return nil;
}
VolumeItem *locateOrAddVolume(NSString *volumePath) {
    for (VolumeItem *volume in volumes) {
        if ([[volume volumePath] isEqualToString:volumePath])    return volume;
    }
    return addVolume(volumePath);
}
// Search all logged volumes for path
DirectoryItem *findPathInVolumes(NSString *path) {
	DirectoryItem *dir;
	for (VolumeItem *volume in volumes) {
		dir = [[volume volumeRoot] findPathInDir:[volume localPath:path]];
		if (dir)    return dir;
	}
	return nil;	// Path not fond
}
