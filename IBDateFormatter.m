//
//  IBDateFormatter.m
//  DateTest
//
//  Created by Ian Binnie on 12/05/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "IBDateFormatter.h"

@implementation IBDateFormatter
static IBDateFormatter *sharedDateFormatter = nil;

+ (IBDateFormatter*)sharedDateFormatter {
    if (sharedDateFormatter == nil) {
        sharedDateFormatter = [[super allocWithZone:NULL] init];
        sharedDateFormatter.writeDateFormatter = [[NSDateFormatter alloc] init];
        sharedDateFormatter.createDateFormatter = [[NSDateFormatter alloc] init];
        sharedDateFormatter->filterDateFormatter = [[NSDateFormatter alloc] init];
        sharedDateFormatter->filter2DateFormatter = [[NSDateFormatter alloc] init];
        sharedDateFormatter->filter3DateFormatter = [[NSDateFormatter alloc] init];
    }
    return sharedDateFormatter;
}
+ (id)allocWithZone:(NSZone *)zone {
    return [self sharedDateFormatter];
}
- (id)copyWithZone:(NSZone *)zone {
    return self;
}
- (void)initialiseFormatters:(NSInteger)dateFormat showCreateTime:(BOOL)showCreateTime useRelativeDate:(BOOL)useRelativeDate {
    switch (dateFormat) {
        case ShortStyle:
        case MediumStyle:
        case LongStyle:
        case FullStyle:
            [self.writeDateFormatter setDateStyle:dateFormat];
            [self.writeDateFormatter setTimeStyle:dateFormat];
            [self.createDateFormatter setDateStyle:dateFormat];
            if(showCreateTime)
                [self.createDateFormatter setTimeStyle:dateFormat];
            else
                [self.createDateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [self.writeDateFormatter setDoesRelativeDateFormatting:useRelativeDate];
            [self.createDateFormatter setDoesRelativeDateFormatting:useRelativeDate];
            break;
        case ISO8601Style:
            [self.writeDateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss"];
            break;
        default:
            [self.writeDateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm"];
            break;
    }
    switch (dateFormat) {
        case ShortStyle:
        case MediumStyle:
            [filterDateFormatter setDateStyle:dateFormat];
            [filterDateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [filter2DateFormatter setDateStyle:LongStyle];
            [filter2DateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [filter3DateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
            break;
        case LongStyle:
        case FullStyle:
            [filterDateFormatter setDateStyle:dateFormat];
            [filterDateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [filter2DateFormatter setDateStyle:ShortStyle];
            [filter2DateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [filter3DateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
            break;
        case ISO8601Style:
        default:
            [filterDateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
            [filter2DateFormatter setDateStyle:ShortStyle];
            [filter2DateFormatter setTimeStyle:NSDateFormatterNoStyle];
            [filter3DateFormatter setDateStyle:LongStyle];
            [filter3DateFormatter setTimeStyle:NSDateFormatterNoStyle];
            if(showCreateTime)
                [self.createDateFormatter setDateFormat:[self.writeDateFormatter dateFormat]];
            else
                [self.createDateFormatter setDateFormat:@"yyyy'-'MM'-'dd"];
            break;
    }
}

// IBDateFormatter dateFromString method - interpret dates according to user's display preferences
- (NSDate *)dateFromString:(NSString *)dateString {
    NSDate *date = [filterDateFormatter dateFromString:dateString];
    if (date)         return date;
    date = [filter2DateFormatter dateFromString:dateString];
    if (date)         return date;
    date = [filter3DateFormatter dateFromString:dateString];
    return date;
}
@end
