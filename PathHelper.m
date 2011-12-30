//
//  PathHelper.m
//  returns Path and Icon for common locations
//
//  Created by Ian Binnie on 11/04/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "PathHelper.h"

@implementation PathHelper
static PathHelper *sharedPathHelper = nil;
#define icon4Type(fileType)[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(fileType)]

+ (PathHelper*)sharedPathHelper {
    if (sharedPathHelper == nil) {
        sharedPathHelper = [[super allocWithZone:NULL] init];
        sharedPathHelper->icons = [NSDictionary dictionaryWithObjectsAndKeys:
                                   icon4Type(kToolbarHomeIcon), @"Home",
                                   icon4Type(kToolbarApplicationsFolderIcon), @"Applications",
                                   icon4Type(kToolbarDocumentsFolderIcon), @"Documents",
                                   icon4Type(kToolbarMovieFolderIcon), @"Movie",
                                   icon4Type(kToolbarMusicFolderIcon), @"Music",
                                   icon4Type(kToolbarPicturesFolderIcon), @"Pictures",
                                   icon4Type(kToolbarPublicFolderIcon), @"Public",
                                   icon4Type(kToolbarDesktopFolderIcon), @"Desktop",
                                   icon4Type(kToolbarDownloadsFolderIcon), @"Downloads",
                                   icon4Type(kToolbarLibraryFolderIcon), @"Library",
                                   icon4Type(kToolbarUtilitiesFolderIcon), @"Utilities",
                                   icon4Type(kUserIcon), @"Users",
                                   [NSImage imageNamed:NSImageNameComputer], @"Computer",
                                   icon4Type(kToolbarSitesFolderIcon), @"Sites",
                                   nil ];
        sharedPathHelper->paths = [NSDictionary dictionaryWithObjectsAndKeys:
                                   NSHomeDirectory(), @"Home",
                                   @"/Applications", @"Applications",
                                   [@"~/Documents" stringByExpandingTildeInPath], @"Documents",
                                   [@"~/Movie" stringByExpandingTildeInPath], @"Movie",
                                   [@"~/Music" stringByExpandingTildeInPath], @"Music",
                                   [@"~/Pictures" stringByExpandingTildeInPath], @"Pictures",
                                   [@"~/Public" stringByExpandingTildeInPath], @"Public",
                                   [@"~/Desktop" stringByExpandingTildeInPath], @"Desktop",
                                   [@"~/Downloads" stringByExpandingTildeInPath], @"Downloads",
                                   [@"~/Library" stringByExpandingTildeInPath], @"Library",
                                   @"/Applications/Utilities", @"Utilities",
                                   @"/Users", @"Users",
                                   @"/", @"Computer",
                                   nil ];
    }
    return sharedPathHelper;    
}

+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedPathHelper];
}
- (NSImage *)iconForPath:(NSString *)path {
    NSImage *iconImage = [icons objectForKey:[path lastPathComponent]];        
	if (iconImage == nil)
		iconImage = [[NSWorkspace sharedWorkspace] iconForFile:path];
    return iconImage;  
}
- (NSImage *)iconForName:(NSString *)name {
    NSImage *iconImage = [icons objectForKey:name];
    return iconImage;  
}
- (NSString *)pathForName:(NSString *)name {
    return [paths objectForKey:name];  
}

@end
