//
//  PathHelper.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 11/04/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PathHelper : NSObject {
    NSDictionary *icons;
    NSDictionary *paths;
}
+ (PathHelper*)sharedPathHelper;
- (NSImage *)iconForPath:(NSString *)path;
- (NSImage *)iconForName:(NSString *)name;
- (NSString *)pathForName:(NSString *)name;
@end
