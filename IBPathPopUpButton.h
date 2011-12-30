//
//  IBPathPopUpButton.h
//  PathChooser Test
//
//  Created by Ian Binnie on 6/05/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IBPathPopUpButton: NSPopUpButton {
    NSString *userSelectedPath;
    NSString *popupPath;
    NSInteger indexSelected;
    id observedObjectForPath;
    NSString *observedKeyPathForPath;
}
- (void)initialisePopUpPath:(NSString *)path;
@property (copy) NSString *popupPath;
@end
