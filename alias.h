//
//  alias.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 21/10/12.
//

/*! @brief	Get target of Alias/symlink
 @param	fPath A string object containing a path to a file.
 @return	An NSString object containing the absolute path of the directory or file to which the Alias/symlink refers, or nil upon failure.
 */
extern NSString *getTarget(NSString *fPath);
/*! @brief	Check Alias (including Symbolic Links) to determine if these target Directories
 @param	url url of Alias/symlink
 @return	BOOL
 */
extern BOOL isAliasFolder(NSURL *url);