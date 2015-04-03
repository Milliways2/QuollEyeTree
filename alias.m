//
//  alias.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 21/10/12.
//
//

#include <sys/stat.h>

NSURL *targetOfAlias(NSURL *url) {
	CFErrorRef *errorRef = NULL;
	CFDataRef bookmark = CFURLCreateBookmarkDataFromFile (NULL, (__bridge CFURLRef)url, errorRef);
	if (bookmark == nil) return nil;
	CFURLRef resolvedUrl = CFURLCreateByResolvingBookmarkData (NULL, bookmark, kCFBookmarkResolutionWithoutUIMask, NULL, NULL, NO, errorRef);
	return CFBridgingRelease(resolvedUrl);
}

BOOL isAliasFolder(NSURL *url) {
	id value = nil;
	NSURL *target;
	[url getResourceValue:&value forKey:NSURLIsSymbolicLinkKey error:nil];
	if ([value boolValue]) {
		target = [url URLByResolvingSymlinksInPath];
        [target getResourceValue:&value forKey:NSURLIsPackageKey error:nil];
        if ([value boolValue])	return NO;	// exclude Packages
        [target getResourceValue:&value forKey:NSURLIsDirectoryKey error:nil];
		return [value boolValue];
	}
	target = targetOfAlias(url);
	[target getResourceValue:&value forKey:NSURLIsDirectoryKey error:nil];
	return [value boolValue];
}
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
	NSURL *resolvedUrl = targetOfAlias([NSURL fileURLWithPath:fPath]);
	return [resolvedUrl path];
}
