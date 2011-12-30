//
//  NSString+Rename.h
//  FileSpecTest
//
//  Created by Ian Binnie on 15/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString(Rename)

- (NSString *)stringByRenamingingPathComponent:(NSString *)renameFilter;
- (NSString *)stringByRenamingingLastPathComponent:(NSString *)renameFilter;

@end
