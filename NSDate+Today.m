//
//  NSDate+Today.m
//  CharTest
//
//  Created by Ian Binnie on 22/05/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "NSDate+Today.h"

@implementation NSDate(Today)
// Creates and returns a new date set to the current day at midnight.
+ (NSDate *)today {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterNoStyle];
    return [formatter dateFromString:[formatter stringForObjectValue:[NSDate date]]];
}
- (NSDate *)previousDay {
    return [self dateByAddingTimeInterval:- SECONDSPERDAY];
}
- (NSDate *)nextDay {
    return [self dateByAddingTimeInterval:SECONDSPERDAY];
}
- (NSDate *)endDay {
    return [self dateByAddingTimeInterval:ENDOFDAY];
}
@end
