//
//  NSString+Rename.m
//  FileSpecTest
//
//  Created by Ian Binnie on 15/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "NSString+Rename.h"


@implementation NSString(Rename)
- (NSString *)stringByRenamingingPathComponent:(NSString *)renameFilter {
	NSRange rangeString = {0, [self length]};	// Original string
	NSRange r, rangeReplace;
	
	while (YES) {
		r = [renameFilter rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*?"]];
		if (r.length == 0)	return renameFilter;	// Nothing to do
		if (!NSLocationInRange(r.location, rangeString)) {	// Past end of string
			renameFilter = [renameFilter stringByReplacingOccurrencesOfString:@"*" withString:@""];
			return [renameFilter stringByReplacingOccurrencesOfString:@"?" withString:@""];
		}
		if ([renameFilter characterAtIndex:r.location] == '*') {
			rangeReplace.location = r.location;
			rangeReplace.length = rangeString.length - r.location;
			return [renameFilter stringByReplacingCharactersInRange:r withString:[self substringWithRange:rangeReplace]];
		}
		rangeReplace = NSIntersectionRange(rangeString, r);
		renameFilter = [renameFilter stringByReplacingCharactersInRange:r withString:[self substringWithRange:rangeReplace]];
	}
}

- (NSString *)stringByRenamingingLastPathComponent:(NSString *)renameFilter {
	NSString *filename = [[self stringByDeletingPathExtension] stringByRenamingingPathComponent:[renameFilter stringByDeletingPathExtension]];
	NSString *ext = [[self pathExtension] stringByRenamingingPathComponent:[renameFilter pathExtension]];
	if ([ext length])
		return [filename stringByAppendingPathExtension:ext];
	return filename;
}

@end