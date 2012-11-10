//
//  TreeViewController+Filter.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 18/05/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "TreeViewController+Filter.h"
#import "NSString+Parse.h"
#import "NSDate+Today.h"
#import "IBDateFormatter.h"

@interface TreeViewController()
- (BOOL)areFilesTagged;
- (void)applyFileAndTagFilter:(NSPredicate *)filePredicate;
@end

#define SPLITSIZE(size, type) \
NSMutableIndexSet *size = [[NSMutableIndexSet alloc] initWithIndexSet:type]; \
[type removeIndexes:notDate]; \
[size removeIndexes:type];

@implementation TreeViewController(Filter)
- (void)resetFileFilter {
	fileFilterPredicate = [NSPredicate predicateWithValue:YES];
	if(showOnlyTagged) {
		if([self areFilesTagged]) {
			[self.arrayController setFilterPredicate:tagPredicate];
			return;
		}
	}
	[self.arrayController setFilterPredicate:nil];
}
NSDate *dateFromString(NSString *dateString) {
    NSDate *date = [[IBDateFormatter sharedDateFormatter] dateFromString:dateString];
    if (date)         return date;
    NSRange today = [dateString rangeOfString:@"TODAY" options:NSCaseInsensitiveSearch|NSAnchoredSearch];
    if (today.length)
        return [[NSDate today] dateByAddingTimeInterval:SECONDSPERDAY*[[dateString substringFromIndex:today.length] integerValue]];
    return [NSDate dateWithTimeIntervalSince1970:0];
}
- (void)applyFileFilter:(NSString *)searchString {
	savedSearchString = [searchString copy];
	if(inFileView)
		[self.fileList.window makeFirstResponder:self.fileList];
	else
		[self.dirTree.window makeFirstResponder:self.dirTree];
	if([searchString length] == 0) {
		[self resetFileFilter];
        return;
    }
	NSArray *searchStringArray = [searchString componentsSeparatedBySpaces];
    NSIndexSet *norm = [searchStringArray indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
        if ([obj length] < 1)   return NO;
        if ([obj characterAtIndex:0] == '!')    return NO;
        if ([obj characterAtIndex:0] == '>')    return NO;
        if ([obj characterAtIndex:0] == '<')    return NO;
        if ([obj characterAtIndex:0] == '=')    return NO;
        if ([obj characterAtIndex:0] == diamond)    return NO;
        return YES;
    }];
	NSMutableIndexSet *notFile = [[NSMutableIndexSet alloc] init];
	[notFile addIndexes:[searchStringArray indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
		if ([obj characterAtIndex:0] == '!')    return YES;
		return NO;
	}]];
	NSMutableIndexSet *greater = [[NSMutableIndexSet alloc] init];
	[greater addIndexes:[searchStringArray indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
		if ([obj characterAtIndex:0] == '>')    return YES;
		return NO;
	}]];
	NSMutableIndexSet *less = [[NSMutableIndexSet alloc] init];
	[less addIndexes:[searchStringArray indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
		if ([obj characterAtIndex:0] == '<')    return YES;
		return NO;
	}]];
	NSMutableIndexSet *equal = [[NSMutableIndexSet alloc] init];
	[equal addIndexes:[searchStringArray indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
		if ([obj characterAtIndex:0] == '=')    return YES;
		return NO;
	}]];
	NSMutableIndexSet *ge = [[NSMutableIndexSet alloc] init];
	[ge addIndexes:[searchStringArray indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
		if ([obj length] < 2)   return NO;
		if ([obj characterAtIndex:0] == '>' && [obj characterAtIndex:1] == '=')   return YES;
		if ([obj characterAtIndex:0] == '=' && [obj characterAtIndex:1] == '>')   return YES;
		return NO;
	}]];
	NSMutableIndexSet *le = [[NSMutableIndexSet alloc] init];
	[le addIndexes:[searchStringArray indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
		if ([obj length] < 2)   return NO;
		if ([obj characterAtIndex:0] == '<' && [obj characterAtIndex:1] == '=')   return YES;
		if ([obj characterAtIndex:0] == '=' && [obj characterAtIndex:1] == '<')   return YES;
		return NO;
	}]];
	NSMutableIndexSet *ne = [[NSMutableIndexSet alloc] init];
	[ne addIndexes:[searchStringArray indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
		if ([obj length] < 2)   return NO;
		if ([obj characterAtIndex:0] == '<' && [obj characterAtIndex:1] == '>')   return YES;
		if ([obj characterAtIndex:0] == '>' && [obj characterAtIndex:1] == '<')   return YES;
		if ([obj characterAtIndex:0] == '!' && [obj characterAtIndex:1] == '=')   return YES;
		return NO;
	}]];
	NSIndexSet *notDate = [searchStringArray indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop) {
		if ([obj length] < 3)   return NO;
		if ([obj characterAtIndex:1] == 's' || [obj characterAtIndex:1] == 'S')   return YES;
		if ([obj characterAtIndex:2] == 's' || [obj characterAtIndex:2] == 'S')   return YES;
		return NO;
	}];
	[notFile removeIndexes:ne];
	[greater removeIndexes:ge];
	[greater removeIndexes:ne];
	[less removeIndexes:le];
	[less removeIndexes:ne];
	[equal removeIndexes:le];
	[equal removeIndexes:ge];
	SPLITSIZE(greaterSize, greater);
	SPLITSIZE(lessSize, less);
	SPLITSIZE(equalSize, equal);
	SPLITSIZE(geSize, ge);
	SPLITSIZE(leSize, le);
	SPLITSIZE(neSize, ne);
	// ________________
	NSUInteger index;
	NSUInteger noItems = [searchStringArray count];
	NSUInteger sizes[noItems];
	NSDate *dates[noItems];
	NSTimeInterval times[noItems];
	for (NSInteger i=0; i<noItems; i++) {
		sizes[i] = 0;
		times[i] = 0;
		dates[i] = nil;
	}
	index = [geSize firstIndex];    // map to >
	while(index != NSNotFound) {
		sizes[index] = [[[searchStringArray objectAtIndex:index] substringFromIndex:3] integerValue] - 1;
		index = [geSize indexGreaterThanIndex:index];
	}
	index = [greaterSize firstIndex];
	while(index != NSNotFound) {
		if(![geSize containsIndex:index])
			sizes[index] = [[[searchStringArray objectAtIndex:index] substringFromIndex:2] integerValue];
		index = [greaterSize indexGreaterThanIndex:index];
	}
	index = [leSize firstIndex];    // map to <
	while(index != NSNotFound) {
		sizes[index] = [[[searchStringArray objectAtIndex:index] substringFromIndex:3] integerValue] + 1;
		index = [leSize indexGreaterThanIndex:index];
	}
	index = [lessSize firstIndex];
	while(index != NSNotFound) {
		if(![leSize containsIndex:index])
			sizes[index] = [[[searchStringArray objectAtIndex:index] substringFromIndex:2] integerValue];
		index = [lessSize indexGreaterThanIndex:index];
	}
	index = [neSize firstIndex];
	while(index != NSNotFound) {
		sizes[index] = [[[searchStringArray objectAtIndex:index] substringFromIndex:3] integerValue];
		index = [neSize indexGreaterThanIndex:index];
	}
	index = [equalSize firstIndex];
	while(index != NSNotFound) {
		sizes[index] = [[[searchStringArray objectAtIndex:index] substringFromIndex:2] integerValue];
		index = [equalSize indexGreaterThanIndex:index];
	}
	[greaterSize addIndexes:geSize];
	[lessSize addIndexes:leSize];
	// ________________
	index = [ge firstIndex];    // map to >
	while(index != NSNotFound) {
		dates[index] = dateFromString([[searchStringArray objectAtIndex:index] substringFromIndex:2]);
		index = [ge indexGreaterThanIndex:index];
	}
	index = [greater firstIndex];
	while(index != NSNotFound) {
		dates[index] = [dateFromString([[searchStringArray objectAtIndex:index] substringFromIndex:1]) endDay];
		index = [greater indexGreaterThanIndex:index];
	}
	index = [le firstIndex];     // map to <
	while(index != NSNotFound) {
		dates[index] = [dateFromString([[searchStringArray objectAtIndex:index] substringFromIndex:2]) nextDay];
		index = [le indexGreaterThanIndex:index];
	}
	index = [less firstIndex];
	while(index != NSNotFound) {
		dates[index] = dateFromString([[searchStringArray objectAtIndex:index] substringFromIndex:1]);
		index = [less indexGreaterThanIndex:index];
	}
	index = [ne firstIndex];
	while(index != NSNotFound) {
		dates[index] = dateFromString([[searchStringArray objectAtIndex:index] substringFromIndex:2]);
		index = [ne indexGreaterThanIndex:index];
	}
	index = [equal firstIndex];
	while(index != NSNotFound) {
		dates[index] = dateFromString([[searchStringArray objectAtIndex:index] substringFromIndex:1]);
		index = [equal indexGreaterThanIndex:index];
	}
	[greater addIndexes:ge];
	[less addIndexes:le];
	// ________________
	BOOL filePredicate, sizePredicate, datePredicate;
	NSPredicate *subpredicate;
	NSMutableArray *filterPredicateArray = [NSMutableArray new];
	index = [norm firstIndex];
	while(index != NSNotFound) {
		subpredicate = [NSPredicate predicateWithFormat:@"relativePath like[c] %@", [searchStringArray objectAtIndex:index]];
		[filterPredicateArray addObject:subpredicate];
		index = [norm indexGreaterThanIndex:index];
	}
	fileFilterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:filterPredicateArray];
	filterPredicateArray = [NSMutableArray new];
	filePredicate = [norm count];
	if (filePredicate)
		[filterPredicateArray addObject:fileFilterPredicate];
	index = [notFile firstIndex];
	while(index != NSNotFound) {
		filePredicate = YES;
		subpredicate = [NSPredicate predicateWithFormat:@"NOT relativePath like[c] %@", [[searchStringArray objectAtIndex:index] substringFromIndex:1]];
		[filterPredicateArray addObject:subpredicate];
		index = [notFile indexGreaterThanIndex:index];
	}
	fileFilterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:filterPredicateArray];
	// ________________
	NSPredicate *sizeFilterPredicate;
	filterPredicateArray = [NSMutableArray new];
	index = [greaterSize firstIndex];
	while(index != NSNotFound) {
		if ([lessSize containsIndex:index+1] && (sizes[index] < sizes[index+1])) {
			subpredicate = [NSPredicate predicateWithFormat:@"fileSize BETWEEN {%u, %u}", sizes[index], sizes[index+1]];
			[lessSize removeIndex:index+1];                //            }
		}
		else
			subpredicate = [NSPredicate predicateWithFormat:@"fileSize > %u", sizes[index]];
		[filterPredicateArray addObject:subpredicate];
		index = [greaterSize indexGreaterThanIndex:index];
	}
	index = [lessSize firstIndex];
	while(index != NSNotFound) {
		subpredicate = [NSPredicate predicateWithFormat:@"fileSize < %u", sizes[index]];
		[filterPredicateArray addObject:subpredicate];
		index = [lessSize indexGreaterThanIndex:index];
	}
	index = [equalSize firstIndex];
	while(index != NSNotFound) {
		subpredicate = [NSPredicate predicateWithFormat:@"fileSize = %u", sizes[index]];
		[filterPredicateArray addObject:subpredicate];
		index = [equalSize indexGreaterThanIndex:index];
	}
	sizeFilterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:filterPredicateArray];
	sizePredicate = [greaterSize count] + [lessSize count] + [equalSize count];
	filterPredicateArray = [NSMutableArray new];
	if (sizePredicate)
		[filterPredicateArray addObject:sizeFilterPredicate];
	index = [neSize firstIndex];
	while(index != NSNotFound) {
		sizePredicate = YES;
		subpredicate = [NSPredicate predicateWithFormat:@"fileSize <> %u", sizes[index]];
		[filterPredicateArray addObject:subpredicate];
		index = [neSize indexGreaterThanIndex:index];
	}
	sizeFilterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:filterPredicateArray];
	// ________________
	NSPredicate *dateFilterPredicate;
	filterPredicateArray = [NSMutableArray new];
	index = [greater firstIndex];
	while(index != NSNotFound) {
		if ([less containsIndex:index+1] && (dates[index] < dates[index+1])) {
			subpredicate = [NSPredicate predicateWithFormat:@"wDate BETWEEN {%@, %@}", dates[index], dates[index+1]];
			[less removeIndex:index+1];
		}
		else
			subpredicate = [NSPredicate predicateWithFormat:@"wDate > %@", dates[index]];
		[filterPredicateArray addObject:subpredicate];
		index = [greater indexGreaterThanIndex:index];
	}
	index = [less firstIndex];
	while(index != NSNotFound) {
		subpredicate = [NSPredicate predicateWithFormat:@"wDate < %@", dates[index]];
		[filterPredicateArray addObject:subpredicate];
		index = [less indexGreaterThanIndex:index];
	}
	index = [equal firstIndex];
	while(index != NSNotFound) {
		subpredicate = [NSPredicate predicateWithFormat:@"wDate BETWEEN {%@, %@}", dates[index], [dates[index] endDay]];
		[filterPredicateArray addObject:subpredicate];
		index = [equal indexGreaterThanIndex:index];
	}
	dateFilterPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:filterPredicateArray];
	datePredicate = [greater count] + [less count] + [equal count];
	filterPredicateArray = [NSMutableArray new];
	if (datePredicate)
		[filterPredicateArray addObject:dateFilterPredicate];
	index = [ne firstIndex];
	while(index != NSNotFound) {
		datePredicate = YES;
		subpredicate = [NSPredicate predicateWithFormat:@"NOT wDate BETWEEN {%@, %@}", dates[index], [dates[index] endDay]];
		[filterPredicateArray addObject:subpredicate];
		index = [ne indexGreaterThanIndex:index];
	}
	dateFilterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:filterPredicateArray];
	// ________________
	filterPredicateArray = [NSMutableArray new];
	if (filePredicate)  [filterPredicateArray addObject:fileFilterPredicate];
	if (sizePredicate)  [filterPredicateArray addObject:sizeFilterPredicate];
	if (datePredicate)  [filterPredicateArray addObject:dateFilterPredicate];
	fileFilterPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:filterPredicateArray];
	// ________________
	[self applyFileAndTagFilter:fileFilterPredicate];
}

@end
