//
//  folderSize.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 27/10/12.

NSNumber *folderSize(NSURL *directoryToScan) {
    NSFileManager *localFileManager=[[NSFileManager alloc] init];
    NSDirectoryEnumerator *dirEnumerator = [localFileManager enumeratorAtURL:directoryToScan
												  includingPropertiesForKeys:[NSArray arrayWithObjects:NSURLFileSizeKey,
																			  nil]
																	 options:0
																errorHandler:nil];
	
	NSNumber *size;
	unsigned long long totalSize = 0;
    for (NSURL *theURL in dirEnumerator) {
		[theURL getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
		totalSize += size.unsignedLongLongValue;
    }
	return[NSNumber numberWithUnsignedLongLong:totalSize];
}
