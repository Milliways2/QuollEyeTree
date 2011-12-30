//
//  FileItem.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 9/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "FileItem.h"

@implementation FileItem

- (NSURL *)url {
    return [NSURL fileURLWithPath:self.fullPath isDirectory:NO];
}

@end
