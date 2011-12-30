//
//  DeletedItems.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 1/02/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

@protocol DeletedItemsDelegate
@optional
- (void)updateDirectory:(NSString *)path;
@end
