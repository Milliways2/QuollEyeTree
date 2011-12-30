//
//  SidebarViewControllerDelegate.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 29/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SidebarViewController;

@protocol SidebarViewControllerDelegate

- (void)sidebarViewController:(SidebarViewController *)svc shouldSelectDirectory:(NSString *)directory inTab:(BOOL)inTab;
- (void)sidebarViewController:(SidebarViewController *)svc shouldRemoveVolume:(NSString *)directory;

@end
