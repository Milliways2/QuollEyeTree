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

@property (strong) IBOutlet NSMatrix *sort;
@property (strong) IBOutlet NSButton *ascending;
@property (strong) IBOutlet NSButton *iconDir;
@property (strong) IBOutlet NSButton *iconFile;
@property (strong) IBOutlet NSButton *hide;
@property (strong) IBOutlet NSButton *refreshDirs;
@property (strong) IBOutlet NSTextField *percentage;
@property (strong) IBOutlet IBPathPopUpButton *defaultPathButton;
@property (strong) IBOutlet IBPathPopUpButton *refreshPathButton;

- (IBAction)sortField:(id)sender;
- (IBAction)sortDirection:(id)sender;
- (IBAction)iconInDirectory:(id)sender;
- (IBAction)iconInFile:(id)sender;
- (IBAction)hiddenFiles:(id)sender;
- (IBAction)automaticRefresh:(id)sender;
- (IBAction)percentageSplit:(id)sender;
- (IBAction)defaultColumns:(id)sender;
- (IBAction)saveColumns:(id)sender;

@property (strong) IBOutlet NSTextField *dateSample;
@property (strong) IBOutlet NSTextField *createDateSample;
@property (strong) IBOutlet NSMatrix *selectDateFormat;
@property (strong) IBOutlet NSButton *relativeDate;
@property (strong) IBOutlet NSButton *createTime;

- (IBAction)formatDate:(id)sender;
- (IBAction)toggleRelative:(id)sender;
- (IBAction)toggleCreateTime:(id)sender;

@end
