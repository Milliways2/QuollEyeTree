//
//  FilterController.h
//  QuollEyeTree
//
//  Created by Ian Binnie on 27/12/12.
//
//

#import <Cocoa/Cocoa.h>

enum {	// filterMode
	DuplicateName,
	DuplicateIdenticalDate,
	DuplicateOldestDate,
	DuplicateNewestDate,
	Unique };

@interface CompareFilterController : NSWindowController
@property (unsafe_unretained) IBOutlet NSMatrix *filterMode;

- (IBAction)performFilter:(id)sender;
- (IBAction)cancelFilter:(id)sender;
- (NSInteger)runModal;

@end
