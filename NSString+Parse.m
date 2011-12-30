//
//  NSString+Parse.m
//
//  Created by Ian Binnie on 21/09/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "NSString+Parse.h"

@implementation NSString(Parse)

// Returns an array containing substrings from the receiver that have been divided by spaces
// Quoted substrings may contain spaces and are returned without quotes
- (NSArray *) componentsSeparatedBySpaces {
	NSRange r;
	NSMutableArray *args = [NSMutableArray new];
	
	NSString *trimmedString = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	
    while([trimmedString length])
	{
		if ([trimmedString characterAtIndex:0] == '\"') {
			trimmedString = [trimmedString substringFromIndex:1];
			r = [trimmedString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
			if (r.length == 0)	{
				[args addObject:trimmedString];
				return args;
			}
			else {
				[args addObject:[trimmedString substringToIndex:r.location]];
				trimmedString = [trimmedString substringFromIndex:r.location+1];
			}
		}
		else {
			r = [trimmedString rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
			if (r.length == 0)	{
				[args addObject:trimmedString];
				return args;
			}
			else {
				[args addObject:[trimmedString substringToIndex:r.location]];
				trimmedString = [trimmedString substringFromIndex:r.location];
			}
		}
		trimmedString = [trimmedString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	}
	return args;
}

@end
