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
	NSDictionary *plistContents;
}
@property (unsafe_unretained) IBOutlet NSButton *sizeMode;
@property (unsafe_unretained) IBOutlet NSButton *sizeTotalMode;
@property (unsafe_unretained) IBOutlet NSMatrix *splitType;

@property (unsafe_unretained) IBOutlet NSMatrix *sort;
@property (unsafe_unretained) IBOutlet NSButton *ascending;
@property (unsafe_unretained) IBOutlet NSButton *iconDir;
@property (unsafe_unretained) IBOutlet NSButton *iconFile;
@property (unsafe_unretained) IBOutlet NSButton *hide;
@property (unsafe_unretained) IBOutlet NSButton *refreshDirs;
@property (unsafe_unretained) IBOutlet NSTextField *percentage;
@property (unsafe_unretained) IBOutlet IBPathPopUpButton *defaultPathButton;
@property (unsafe_unretained) IBOutlet IBPathPopUpButton *refreshPathButton;

- (IBAction)splitAppearance:(id)sender;
- (IBAction)sortField:(id)sender;
- (IBAction)sortDirection:(id)sender;
- (IBAction)iconInDirectory:(id)sender;
- (IBAction)iconInFile:(id)sender;
- (IBAction)hiddenFiles:(id)sender;
- (IBAction)automaticRefresh:(id)sender;
- (IBAction)percentageSplit:(id)sender;
- (IBAction)defaultColumns:(id)sender;
- (IBAction)saveColumns:(id)sender;

@property (unsafe_unretained) IBOutlet NSTextField *dateSample;
@property (unsafe_unretained) IBOutlet NSTextField *createDateSample;
@property (unsafe_unretained) IBOutlet NSMatrix *selectDateFormat;
@property (unsafe_unretained) IBOutlet NSButton *relativeDate;
@property (unsafe_unretained) IBOutlet NSButton *createTime;

- (IBAction)formatDate:(id)sender;
- (IBAction)toggleRelative:(id)sender;
- (IBAction)toggleCreateTime:(id)sender;
- (IBAction)sizeFormat:(id)sender;

@property (unsafe_unretained) IBOutlet NSComboBox *compareProgram;
- (IBAction)compareCmdSelected:(NSComboBox *)sender;
@property (unsafe_unretained) IBOutlet NSTextField *editProgram;
- (IBAction)editCmdSelected:(NSTextField *)sender;


@end
