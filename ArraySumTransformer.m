//
//  ArraySumTransformer.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 25/12/12.
//
//

#import "ArraySumTransformer.h"

@implementation ArraySumTransformer
+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)value {
	NSUInteger sum = 0;
    if ([value isKindOfClass:[NSArray class]]) {
		for (NSNumber *n in value) {
			sum += [n intValue];
		}
	}
    return [NSNumber numberWithInt:sum];
}

@end
