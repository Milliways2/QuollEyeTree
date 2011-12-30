//
//  NSDate+Today.h
//  CharTest
//
//  Created by Ian Binnie on 22/05/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SECONDSPERDAY 24 * 60 * 60
#define ENDOFDAY (SECONDSPERDAY - 0.001)

@interface NSDate(Today)
+ (NSDate *)today;
- (NSDate *)previousDay;
- (NSDate *)nextDay;
- (NSDate *)endDay;
@end
