//
//  TextViewController.h
//
//  Created by Ian Binnie on 24/06/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MyTextView;

@interface TextViewerController : NSViewController {
    IBOutlet MyTextView *myTextView;
    NSMutableArray *foundRanges;
    NSUInteger visibleIndex;
    NSString *_searchString;
    BOOL _regexSearch;
    BOOL _caseSensitive;
}

@property (assign) IBOutlet NSTextField *fileName;
@property (assign) id delegate;
- (id)initWithPath:(NSString *)path;
- (void)searchFirst:(NSString *)searchString regexSearch:(BOOL)regexSearch caseSensitive:(BOOL)caseSensitive;
@end

@protocol TextViewerControllerDelegate
- (void)exitTextView:(TextViewerController *)tvc;
- (void)nextFile:(TextViewerController *)tvc;
- (void)previousFile:(TextViewerController *)tvc;
@end

