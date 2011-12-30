//
//  FileItem.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 9/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileSystemItem.h"

@interface FileItem: FileSystemItem {
}

@property (strong) NSNumber *fileSize;
@property (assign) BOOL tag;

@end
