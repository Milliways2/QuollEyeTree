//
//  OpenWith.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 22/01/12.
//  Copyright 2012 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface OpenWith : NSObject {
    NSMutableArray *openWithApplications;
	NSURL *urlToOpen;
	NSMenu *openWithMenu;
}
- (id)initMenu:(NSURL *)url;
- (void)openInDefault:(id)sender;
- (void)openInSelected:(id)sender;

@property (strong, readonly) NSMenu *openWithMenu;

@end
