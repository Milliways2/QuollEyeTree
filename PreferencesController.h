//
//  PreferencesController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 23/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class IBPathPopUpButton;

@interface PreferencesController : NSWindowController {
}
@property (unsafe_unretained) IBOutlet NSButton *sizeMode;
@property (unsafe_unretained) IBOutlet NSButton *sizeTotalMode;

@property (assign) IBOutlet NSMatrix *sort;
@property (assign) IBOutlet NSButton *ascending;
@property (assign) IBOutlet NSButton *iconDir;
@property (assign) IBOutlet NSButton *iconFile;
@property (assign) IBOutlet NSButton *hide;
@property (assign) IBOutlet NSButton *refreshDirs;
@property (assign) IBOutlet NSTextField *percentage;
@property (assign) IBOutlet IBPathPopUpButton *defaultPathButton;
@property (assign) IBOutlet IBPathPopUpButton *refreshPathButton;

- (IBAction)sortField:(id)sender;
- (IBAction)sortDirection:(id)sender;
- (IBAction)iconInDirectory:(id)sender;
- (IBAction)iconInFile:(id)sender;
- (IBAction)hiddenFiles:(id)sender;
- (IBAction)automaticRefresh:(id)sender;
- (IBAction)percentageSplit:(id)sender;
- (IBAction)defaultColumns:(id)sender;
- (IBAction)saveColumns:(id)sender;

@property (assign) IBOutlet NSTextField *dateSample;
@property (assign) IBOutlet NSTextField *createDateSample;
@property (assign) IBOutlet NSMatrix *selectDateFormat;
@property (assign) IBOutlet NSButton *relativeDate;
@property (assign) IBOutlet NSButton *createTime;

- (IBAction)formatDate:(id)sender;
- (IBAction)toggleRelative:(id)sender;
- (IBAction)toggleCreateTime:(id)sender;
- (IBAction)sizeFormat:(id)sender;

@end
