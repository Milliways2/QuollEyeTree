//
//  PreferencesController.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 23/07/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "PreferencesController.h"
#import "QuollEyeTreeAppDelegate.h"
#import "MyWindowController.h"
#import "TreeViewController.h"
#import "IBDateFormatter.h"
#import "IBPathPopUpButton.h"

@implementation PreferencesController

NSArray *sortColumns;

- (IBAction)sortField:(id)sender {
	[[NSUserDefaults standardUserDefaults]
	 setObject:[sortColumns objectAtIndex:[[sender selectedCell] tag]]
	 forKey:PREF_SORT_FIELD];	
}
- (IBAction)sortDirection:(id)sender {
	[[NSUserDefaults standardUserDefaults]
	 setBool:[self.ascending state]
	 forKey:PREF_SORT_DIRECTION];	
}
- (IBAction)iconInDirectory:(id)sender {
	[[NSUserDefaults standardUserDefaults]
	 setBool:[self.iconDir state]
	 forKey:PREF_DIRECTORY_ICON];	
}
- (IBAction)iconInFile:(id)sender {
	[[NSUserDefaults standardUserDefaults]
	 setBool:[self.iconFile state]
	 forKey:PREF_FILE_ICON];	
}
- (IBAction)hiddenFiles:(id)sender {
	[[NSUserDefaults standardUserDefaults]
	 setBool:[self.hide state]
	 forKey:PREF_HIDDEN_FILES];	
}
- (IBAction)automaticRefresh:(id)sender {
	[[NSUserDefaults standardUserDefaults]
	 setBool:[self.refreshDirs state]
	 forKey:PREF_AUTOMATIC_REFRESH];	
}
- (IBAction)percentageSplit:(id)sender {
	[[NSUserDefaults standardUserDefaults]
	 setFloat:[self.percentage floatValue]
	 forKey:[[[(QuollEyeTreeAppDelegate *)[NSApp delegate] myWindowController] currentTvc] sidebyside]
			 ? PREF_SPLIT_PERCENTAGE_H : PREF_SPLIT_PERCENTAGE ];
}
- (IBAction)splitAppearance:(id)sender {
	NSLog(@"splitAppearance %ld", (long)[sender selectedRow]);
	[[NSUserDefaults standardUserDefaults]
	 setBool:[sender selectedRow]
	 forKey:PREF_SPLIT_ORIENTATION ];
}

#pragma mark Columns
- (IBAction)defaultColumns:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_FILE_COLUMN_WIDTH];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_FILE_COLUMN_HIDDEN];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_FILE_COLUMN_ORDER];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_DIR_COLUMN_WIDTH];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_DIR_COLUMN_HIDDEN];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:PREF_DIR_COLUMN_ORDER];
}
- (IBAction)saveColumns:(id)sender {
	[[[(QuollEyeTreeAppDelegate *)[NSApp delegate] myWindowController] currentTvc] saveTableColumns];	// Xcode 6.1 error
}
#pragma mark Date Format
- (void)showDate {
    NSDate *date = [NSDate dateWithString:@"2000-09-28 10:00:00 +0000"];
    [self.dateSample setStringValue:[[IBDateFormatter sharedDateFormatter].writeDateFormatter stringFromDate:date]];  
    [self.createDateSample setStringValue:[[IBDateFormatter sharedDateFormatter].createDateFormatter stringFromDate:date]];  
    [self.dateSample sizeToFit];
    [self.createDateSample sizeToFit];
	NSDictionary *widths = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithInteger:NSWidth([self.dateSample frame])], COLUMNID_DATE,
                            [NSNumber numberWithInteger:NSWidth([self.createDateSample frame])], COLUMNID_CREATION,
                            nil];
    [[NSUserDefaults standardUserDefaults] setObject:widths forKey:PREF_DATE_WIDTH];
    [[NSNotificationCenter defaultCenter] postNotificationName:PreferencesControllerDateWidthsDidChangeNotification object:self];
}
- (IBAction)toggleRelative:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:[self.relativeDate state] forKey:PREF_DATE_RELATIVE];
    [[IBDateFormatter sharedDateFormatter] initialiseFormatters:[[self.selectDateFormat selectedCell] tag] showCreateTime:[self.createTime state] useRelativeDate:[self.relativeDate state]];
    [self showDate];
}
- (IBAction)toggleCreateTime:(id)sender {
	[[NSUserDefaults standardUserDefaults] setBool:[self.createTime state] forKey:PREF_DATE_SHOW_CREATE];
    [[IBDateFormatter sharedDateFormatter] initialiseFormatters:[[self.selectDateFormat selectedCell] tag] showCreateTime:[self.createTime state] useRelativeDate:[self.relativeDate state]];
    [self showDate];
}
- (IBAction)formatDate:(id)sender {
    NSInteger selectedTag = [[sender selectedCell] tag];    // Requires Tag to match NSDateFormatterStyle enum
    switch (selectedTag) {
        case ShortStyle:
        case MediumStyle:
        case LongStyle:
        case FullStyle:
            [self.relativeDate setEnabled:YES];
            break;
        case ISO8601Style:
            [self.relativeDate setEnabled:NO];
            [self.relativeDate setState:NO];
            break;
        default:
            selectedTag = ISO8601ShortStyle;
            [self.relativeDate setEnabled:NO];
            [self.relativeDate setState:NO];
            break;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:selectedTag forKey:PREF_DATE_FORMAT];	
	[[NSUserDefaults standardUserDefaults] setBool:[self.relativeDate state] forKey:PREF_DATE_RELATIVE];	
    [[IBDateFormatter sharedDateFormatter]
     initialiseFormatters:selectedTag showCreateTime:[self.createTime state] useRelativeDate:[self.relativeDate state]];
    [self showDate];
}
- (IBAction)sizeFormat:(id)sender {
	[[NSUserDefaults standardUserDefaults]
	 setBool:[self.sizeMode state]
	 forKey:PREF_SIZE_MODE];
	[[NSUserDefaults standardUserDefaults]
	 setBool:[self.sizeTotalMode state]
	 forKey:PREF_TOTAL_MODE];
}
- (IBAction)compareCmdSelected:(id)sender {
	NSInteger index = [sender indexOfSelectedItem];
	if (index >= 0 && index < [plistContents count]) {
		[[NSUserDefaults standardUserDefaults]
		 setObject:[plistContents objectForKey:[self.compareProgram stringValue]]
		 forKey:PREF_COMPARE_COMMAND];
		return;
	}
	[[NSUserDefaults standardUserDefaults]
	 setObject:[self.compareProgram stringValue]
	 forKey:PREF_COMPARE_COMMAND];
}
- (IBAction)editCmdSelected:(id)sender {
	[[NSUserDefaults standardUserDefaults]
	 setObject:[self.editProgram stringValue]
	 forKey:PREF_EDIT_COMMAND];
}

#pragma mark -
- (void)awakeFromNib {
	sortColumns = [NSArray arrayWithObjects:COLUMNID_NAME, COLUMNID_SIZE, COLUMNID_DATE, nil];
	[self.sort selectCellWithTag:[sortColumns indexOfObject:[[NSUserDefaults standardUserDefaults] stringForKey:PREF_SORT_FIELD]]];
	[self.ascending setState:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_SORT_DIRECTION]];
	[self.iconDir setState:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_DIRECTORY_ICON]];
	[self.iconFile setState:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_FILE_ICON]];
	[self.hide setState:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_HIDDEN_FILES]];
	[self.refreshDirs setState:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_AUTOMATIC_REFRESH]];
	[self.percentage setFloatValue:[[NSUserDefaults standardUserDefaults]floatForKey:[[[(QuollEyeTreeAppDelegate *)[NSApp delegate] myWindowController] currentTvc] sidebyside] ? PREF_SPLIT_PERCENTAGE_H : PREF_SPLIT_PERCENTAGE] ];
	[self.splitType selectCellAtRow:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_SPLIT_ORIENTATION] column:0];
    [self.defaultPathButton bind:@"popupPath"
						toObject:[NSUserDefaultsController sharedUserDefaultsController]
					 withKeyPath:@"values.defaultDirectory"
						 options:nil];
    [self.refreshPathButton bind:@"popupPath"
						toObject:[NSUserDefaultsController sharedUserDefaultsController]
					 withKeyPath:@"values.refreshDirectory"
						 options:nil];
    [self.selectDateFormat selectCellWithTag:[[NSUserDefaults standardUserDefaults]integerForKey:PREF_DATE_FORMAT]];
    [self.relativeDate setState:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_DATE_RELATIVE]];
	[self.createTime setState:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_DATE_SHOW_CREATE]];
    [self showDate];
    [self.sizeMode setState:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_SIZE_MODE]];
    [self.sizeTotalMode setState:[[NSUserDefaults standardUserDefaults]boolForKey:PREF_TOTAL_MODE]];
	plistContents = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"CompareCmds" ofType:@"plist"]];
	NSString *cmd = [[NSUserDefaults standardUserDefaults] stringForKey:PREF_COMPARE_COMMAND];
	BOOL cmdFound = FALSE;
	for (NSString *key in plistContents) {
		[self.compareProgram addItemWithObjectValue:key];
		if ([cmd isEqualToString:[plistContents objectForKey:key]]) {
			[self.compareProgram selectItemWithObjectValue:key];
			cmdFound = TRUE;
		}
	}
	if (!cmdFound) {
		[self.compareProgram addItemWithObjectValue:cmd];
		[self.compareProgram selectItemWithObjectValue:cmd];
	}
	[self.editProgram setStringValue:[[NSUserDefaults standardUserDefaults] stringForKey:PREF_EDIT_COMMAND] ];
}

@end
