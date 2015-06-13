//
//  FileItem.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 9/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FileSystemItem.h"

/*! @class FileItem

 @brief The FileItem class

 @discussion    This class containing common properties/methods to support Files.
 */
@interface FileItem: FileSystemItem {
}

/*! @brief size of file */
@property (strong) NSNumber *fileSize;
@property (assign) BOOL tag;

@end
