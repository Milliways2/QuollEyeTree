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
@property (assign) IBOutlet NSTextField *source, *name;
@property (assign) IBOutlet NSComboBox *destComboBox;
@property (assign) IBOutlet NSButton *replaceExisting;
@property (assign) IBOutlet NSButton *createDirectories;
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
