//
//  DeletedItems.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 1/02/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DeletedItems: NSObject {
    id delegate;
    NSMutableArray *items;
    NSString *dataFile;
    NSMenu *putBackMenu;
}

+ (DeletedItems*)sharedDeletedItems;
- (void)addObject:(id)anObject;
- (void)addWithPath:(NSString *)path trashLocation:(NSString *)trash;
- (NSMenu *)restoreMenu;

@property id delegate;
@end
