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
- (NSArray *)directoriesInBranch;
- (void)updateBranch;

@end
