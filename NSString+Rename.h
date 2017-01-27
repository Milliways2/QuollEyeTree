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
/*! @brief  Rename the last path component (abc.xyz) of the receiver in accordance with the renameFilter
 @discussion The mask may contain * ? or / (which deletes the character at that position)
 @param	renameFilter containing the rename mask
 */
- (NSString *)stringByRenamingingLastPathComponent:(NSString *)renameFilter;

@end
