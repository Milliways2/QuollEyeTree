//
//  CopyPanelController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 14/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface CopyPanelController: NSWindowController {
}
@property (strong) IBOutlet NSTextField *source, *name;
@property (strong) IBOutlet NSComboBox *destComboBox;
@property (strong) IBOutlet NSButton *replaceExisting;
@property (strong) IBOutlet NSButton *createDirectories;
- (IBAction)cancelCopy:(id)sender;
- (IBAction)performCopy:(id)sender;

- (NSInteger)runModal;
- (void)setTitle:(NSString *)title;
- (void)setFrom:(NSString *)filename;
- (void)setFilename:(NSString *)name;
- (void)setTargetDirs:(NSArray *)target;
- (void)setSelectedDir:(NSInteger)n;
- (NSString *)filename;
- (NSString *)targetDirectory;

@end
