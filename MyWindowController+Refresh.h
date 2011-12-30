//
//  MyWindowController+Refresh.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 2/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MyWindowController.h"

@interface MyWindowController(Refresh)

- (void)startMonitoring;
- (void)stopMonitoring;
- (void)pauseMonitoring:(BOOL)pause;
@end
