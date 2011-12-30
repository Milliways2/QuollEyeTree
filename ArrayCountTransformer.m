//
//  ArrayCountTransformer.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 3/06/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "ArrayCountTransformer.h"

@implementation ArrayCountTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
    NSUInteger result = 0;
    if ([value isKindOfClass:[NSArray class]])
        result = [value count];
    return [NSNumber numberWithInt:result];
}

@end
