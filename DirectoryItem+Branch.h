//
//  DirectoryItem+Branch.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 15/11/12.
//
//

#import "DirectoryItem.h"

@interface DirectoryItem (Branch)
- (NSMutableArray *)filesInBranch;
/*! @brief log all subdirectories in Branch
 */
- (void)logBranch;
/*! @brief get all logged subdirectories in Branch
 @return NSArray containing all logged SubDirectories in the Branch.
 */
- (NSArray *)directoriesInBranch;
- (void)updateBranch;

@end
