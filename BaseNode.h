/*
     File: BaseNode.h 
 Abstract: Generic multi-use node object used with NSOutlineView and NSTreeController.
  
  Version: 1.1 
*/

#import <Cocoa/Cocoa.h>

@interface BaseNode: NSObject <NSCoding, NSCopying> {
	BOOL			isLeaf;
	NSString		*nodePath;
}

- (id)initLeaf;

@property (copy) NSString *nodeTitle;
@property (strong) NSMutableArray *children;
@property (strong) NSImage *nodeIcon;   // bug fix for Xcode 4.4.1
- (void)setLeaf:(BOOL)flag;
- (BOOL)isLeaf;
- (void)setPath:(NSString *)name;
- (NSString *)path;

- (NSArray *)mutableKeys;

@end
