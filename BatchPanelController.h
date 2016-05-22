//
//  BatchPanelController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 13/06/2015.
//
//

#import <Cocoa/Cocoa.h>


/*! @class BatchPanelController

 @brief The BatchPanelController class

 @discussion    This creates a BatchPanel and contains supporting Methods.
 */
@interface BatchPanelController: NSWindowController {
}
@property (assign) IBOutlet NSTextField *batchFileName;
@property (assign) IBOutlet NSTextField *batchArgs;
@property (assign) IBOutlet NSComboBox *destComboBox;
@property (assign) IBOutlet NSButton *replaceBatchFile;
@property (assign) IBOutlet NSButton *makeNameUnique;
- (IBAction)cancelBatch:(id)sender;
- (IBAction)performBatch:(id)sender;
- (IBAction)editCmdSelected:(NSTextField *)sender;

- (NSInteger)runModal;
- (void)setTargetDirs:(NSArray *)target;
- (NSString *)targetDirectory;

@end
