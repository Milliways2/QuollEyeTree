//
//  CompareFileController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 2/12/12.
//
//

#import <Cocoa/Cocoa.h>

@interface CompareFileController : NSWindowController

@property (assign) IBOutlet NSTextField *source;
@property (assign) IBOutlet NSComboBox *name;
@property (assign) IBOutlet NSComboBox *destComboBox;
@property (assign) id delegate;
- (IBAction)cancelCompare:(id)sender;
- (IBAction)performCompare:(id)sender;
- (IBAction)targetDirSelected:(id)sender;

- (NSInteger)runModal;
- (void)setFrom:(NSString *)filename;
- (void)setFilename:(NSString *)filename;
- (void)setTargetDirs:(NSArray *)target;
- (void)setSelectedTarget:(NSInteger)n;
- (void)setTargetNames:(NSArray *)target;
- (void)setSelectedName:(NSInteger)n;
- (NSString *)filename;
- (NSString *)targetDirectory;
@end

@protocol CompareFileControllerDelegate
- (void)compareFileController:(CompareFileController *)compareFileController didSelectTabAtIndex:(NSInteger)index;
@end
