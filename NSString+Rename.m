//
//  NSString+Rename.m
//  FileSpecTest
//
//  Created by Ian Binnie on 15/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "NSString+Rename.h"
NSString *const DEL_CHAR_MARKER = @"\0";

@implementation NSString(Rename)
- (NSString *)stringByRenamingingPathComponent:(NSString *)renameFilter {
	NSRange rangeString = {0, [self length]};	// Original string
	NSRange r, rangeReplace;
	
	while (YES) {
		r = [renameFilter rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*?/"]];
		if (r.length == 0)	return [renameFilter stringByReplacingOccurrencesOfString:DEL_CHAR_MARKER withString:@""];	// Nothing more to do
		if (!NSLocationInRange(r.location, rangeString)) {	// Past end of string
			renameFilter = [renameFilter stringByReplacingOccurrencesOfString:@"*" withString:@""];
			renameFilter = [renameFilter stringByReplacingOccurrencesOfString:@"/" withString:@""];
			renameFilter = [renameFilter stringByReplacingOccurrencesOfString:@"?" withString:@""];
			return [renameFilter stringByReplacingOccurrencesOfString:DEL_CHAR_MARKER withString:@""];
		}
		if ([renameFilter characterAtIndex:r.location] == '*') {
			rangeReplace.location = r.location;
			rangeReplace.length = rangeString.length - r.location;
			renameFilter = [renameFilter stringByReplacingCharactersInRange:r withString:[self substringWithRange:rangeReplace]];
			return [renameFilter stringByReplacingOccurrencesOfString:DEL_CHAR_MARKER withString:@""];
		}
		if ([renameFilter characterAtIndex:r.location] == '/') {
			renameFilter = [renameFilter stringByReplacingCharactersInRange:r withString:DEL_CHAR_MARKER];	// Marker so length doesn't change
		}
		else {
			rangeReplace = NSIntersectionRange(rangeString, r);
			renameFilter = [renameFilter stringByReplacingCharactersInRange:r withString:[self substringWithRange:rangeReplace]];
		}
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