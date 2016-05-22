//
//  NSString+Volume.m
//
//  Created by Ian Binnie on 13/04/2015.
//  Copyright (c) 2015 Ian Binnie. All rights reserved.
//

#import "volumeForPath.h"

@implementation NSString(Volume)

NSString *volumeForPath(NSString *path) {
	NSArray *components = [path pathComponents];
	return [NSString pathWithComponents:[components
										 subarrayWithRange:NSMakeRange(0,
																	   ([components count]>2 && [[components objectAtIndex:1] isEqualToString:@"Volumes"])
																	   ? 3 : 1)]];
}

@end
