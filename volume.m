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
	VolumeItem *newVolume = [VolumeItem new];	// Add new Volume
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
DirectoryItem *findPathInVolumes(NSString *directory) {
	DirectoryItem *dir;
	for (VolumeItem *volume in volumes) {
		dir = [[volume volumeRoot] findPathInDir:[volume relativePathOnVolume:directory]];
		if (dir)    return dir;
	}
	return nil;	// Path not fond
}
DirectoryItem *locateOrAddDirectoryInVolumes(NSString *directory) {
	NSURL *url = [NSURL fileURLWithPath:directory isDirectory:YES];
	VolumeItem *volume;
	id value = nil;
	[url getResourceValue:&value forKey:NSURLIsVolumeKey error:nil];
	if ([value boolValue]) {    // if directory is a Volume locate or add
        volume = locateOrAddVolume(directory);
		return volume.volumeRoot;
	}

	NSURL *vol;
	[url getResourceValue:&vol forKey:NSURLVolumeURLKey error:nil];
    volume = locateOrAddVolume([vol path]);
	DirectoryItem *userDir = [volume.volumeRoot loadPath:[volume relativePathOnVolume:directory] expandHidden:YES];
	return userDir;
}
