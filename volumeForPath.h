//
//  NSString+Volume.h
//  CharTest
//
//  Created by Ian Binnie on 13/04/2015.
//  Copyright (c) 2015 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString(Volume)

/*! @brief	Get volume part of a file path
 @param	path A string object containing an absolute path to a file.
 @discussion Returns either / or /Volumes/volname.
 @return	An NSString object containing the Volume part of the file path.
 */
NSString *volumeForPath(NSString *path);

@end
