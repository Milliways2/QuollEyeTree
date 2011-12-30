//
//  IBDateFormatter.h
//  DateTest
//
//  Created by Ian Binnie on 12/05/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    ShortStyle  =    NSDateFormatterShortStyle, 
    MediumStyle =    NSDateFormatterMediumStyle,
    LongStyle   =    NSDateFormatterLongStyle,  
    FullStyle   =    NSDateFormatterFullStyle, 
    ISO8601Style =  5,
    ISO8601ShortStyle =  6
} IBDateFormatterStyle;

@interface IBDateFormatter : NSObject {
    NSDateFormatter *filterDateFormatter;
    NSDateFormatter *filter2DateFormatter;
    NSDateFormatter *filter3DateFormatter;
}

@property (strong) NSDateFormatter *writeDateFormatter;
@property (strong) NSDateFormatter *createDateFormatter;
+ (IBDateFormatter*)sharedDateFormatter;
- (void)initialiseFormatters:(NSInteger)dateFormat showCreateTime:(BOOL)showCreateTime useRelativeDate:(BOOL)useRelativeDate;
- (NSDate *)dateFromString :(NSString *)dateString;

@end
