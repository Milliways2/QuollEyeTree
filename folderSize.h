//
//  folderSize.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 27/10/12.
//
//

/*! @brief	Get size of a directory
 @param	directoryToScan url of directory.
 @return	An NSNumber object containing the size of a directory, formed by summing components.
 */
extern NSNumber *folderSize(NSURL *directoryToScan);
