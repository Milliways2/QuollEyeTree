//
//  IBPathField.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 16/04/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IBPathTextField : NSTextField <NSTextFieldDelegate> {
    NSMutableArray *possibleMatches;
}

@end
