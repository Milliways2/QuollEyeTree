//
//  TreeViewController+Filter.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 18/05/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TreeViewController.h"
#define diamond 0x2662   
#define marked @"\u2662 "

@interface TreeViewController(Filter) 

- (void)applyFileFilter:(NSString *)searchString;

@end
