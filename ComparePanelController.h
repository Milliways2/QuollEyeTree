//
//  ComparePanelController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 30/12/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ComparePanelController: NSWindowController {
}
@property IBOutlet NSTextField *source;
@property IBOutlet NSComboBox *destComboBox;
@property IBOutlet NSMatrix *compareMode;
@property IBOutlet NSButton *compareIdentical;
@property IBOutlet NSButton *compareUnique;
@property IBOutlet NSButton *dateNewer;
@property IBOutlet NSButton *dateSame;
@property IBOutlet NSButton *dateOlder;
@property IBOutlet NSButton *sizeSmaller;
@property IBOutlet NSButton *sizeEqual;
@property IBOutlet NSButton *sizeLarger;
@property IBOutlet NSButton *sameContent;
@property IBOutlet NSButton *diffContent;
- (IBAction)cancelCompare:(id)sender;
- (IBAction)performCompare:(id)sender;
- (IBAction)contentCompare:(id)sender;

+ (ComparePanelController *)singleton;
- (NSInteger)runModal;
- (void)setTitle:(NSString *)title;
- (void)setFrom:(NSString *)filename;
- (void)setTargetDirs:(NSArray *)target;
- (void)setSelectedDir:(NSInteger)n;
- (NSString *)targetDirectory;

@end
