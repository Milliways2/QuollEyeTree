//
//  alias.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 21/10/12.
//
//

#include <sys/stat.h>

// get target of Symlink or Alias
NSString *getTarget(NSString *fPath) {
	NSString *resolvedPath = nil;
	// Use lstat to determine if the file is a symlink
	struct stat fileInfo;
	NSFileManager *fileManager = [NSFileManager new];
	if (lstat([fileManager fileSystemRepresentationWithPath:fPath], &fileInfo) < 0)
		return nil;
	if (S_ISLNK(fileInfo.st_mode)) {
		// Resolve the symlink component in the path
		NSError *error = nil;
		resolvedPath = [fileManager destinationOfSymbolicLinkAtPath:fPath error:&error];
		if (resolvedPath == nil) {
			NSAlert *alert = [NSAlert alertWithError:error];
			[alert runModal];
			return nil;
		}
		if ([resolvedPath isAbsolutePath])
			return resolvedPath;
		else
			return [[fPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:resolvedPath];
	}
	// Resolve alias
//	CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef)fPath, kCFURLPOSIXPathStyle, NO);
	CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (CFStringRef)fPath, kCFURLPOSIXPathStyle, NO);
	FSRef fsRef;
	if (CFURLGetFSRef((CFURLRef)url, &fsRef)) {
		Boolean targetIsFolder, wasAliased;
		OSErr err = FSResolveAliasFile (&fsRef, true, &targetIsFolder, &wasAliased);
		//		Resolves an alias contained in an alias file. (Deprecated in OS X v10.8. First use CFURLCreateBookmarkDataFromFile, then use CFURLCreateByResolvingBookmarkData.)
		//		CFDataRef CFURLCreateBookmarkDataFromFile (
		//												   CFAllocatorRef allocator,
		//												   CFURLRef       fileURL,
		//												   CFErrorRef     *errorRef
		//												   );
		//		CFURLRef CFURLCreateByResolvingBookmarkData (
		//													 CFAllocatorRef                 allocator,
		//													 CFDataRef                      bookmark,
		//													 CFURLBookmarkResolutionOptions options,
		//													 CFURLRef                       relativeToURL,
		//													 CFArrayRef                     resourcePropertiesToInclude,
		//													 Boolean                        *isStale,
		//													 CFErrorRef                     *error
		//													 );
		if ((err == noErr) && wasAliased) {
			CFURLRef resolvedUrl = CFURLCreateFromFSRef(kCFAllocatorDefault, &fsRef);
			if (resolvedUrl != NULL) {
				resolvedPath = (NSString*)CFBridgingRelease(CFURLCopyFileSystemPath(resolvedUrl, kCFURLPOSIXPathStyle));
				//				CFBridgingRelease(CFBridgingRetain(resolvedPath));
				CFRelease(resolvedUrl);
			}
		}
	}
	CFRelease(url);
	return resolvedPath;
}

