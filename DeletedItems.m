//
//  DeletedItems.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 1/02/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "DeletedItems.h"
#import "DeletedItemsDelegate.h"

#define MaxDeleted 25
@implementation DeletedItems
@synthesize delegate;

static DeletedItems *sharedDeletedItems = nil;

+ (DeletedItems*)sharedDeletedItems {
    if (sharedDeletedItems == nil) {
        sharedDeletedItems = [[super allocWithZone:NULL] init];
    }
    return sharedDeletedItems;
}

-(void) setSupportFile {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *appSupport = 
    [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *dir = [NSString stringWithFormat:@"%@/QuollEyeTree", appSupport];
    [fileManager createDirectoryAtPath:dir 
           withIntermediateDirectories:YES 
                            attributes:nil 
                                 error: nil];
    dataFile = [dir stringByAppendingPathComponent:@"deletedItems.plist"];
}
- (void) validateDeletedItems {
    NSFileManager *fileManager = [NSFileManager defaultManager];
	NSIndexSet *notInTrash = [items indexesOfObjectsPassingTest:^(id obj, NSUInteger index, BOOL *stop){
		if ([fileManager fileExistsAtPath:[(NSDictionary *)obj objectForKey:@"trashLocation"]])	return NO;
		return YES;
	}];
	if([notInTrash count]) {
		[items removeObjectsAtIndexes:notInTrash];	// remove entries not  in trash
        [items writeToFile:dataFile atomically:YES];
    }
}
- (id)init {
    [self setSupportFile];
    if([[NSFileManager defaultManager] fileExistsAtPath:dataFile]) {
        items = [NSMutableArray arrayWithContentsOfFile:dataFile];
        [self validateDeletedItems];
    } else {
        items = [NSMutableArray arrayWithCapacity:MaxDeleted];
    }
    return self;
}

- (void)addObject:(id)anObject {
    if ([items count] >= MaxDeleted) [items removeObjectAtIndex:[items count] - 1];
    [items insertObject:anObject atIndex:0];
    [items writeToFile:dataFile atomically:YES];
}

- (void)addWithPath:(NSString *)path trashLocation:(NSString *)trash {
    NSDictionary *item = [NSDictionary dictionaryWithObjectsAndKeys:
                          path, @"path",
                          trash, @"trashLocation",
                          [NSDate date], @"deletedDate",
                          nil ];
    [self addObject:item];
}
- (void) putBackItem:(id)sender {
	NSInteger idx = [putBackMenu indexOfItem:sender];
    NSDictionary *deletedItem = [items objectAtIndex:idx];
    
    NSFileManager *fileManager = [NSFileManager new];
    NSError *error = nil;
    if([fileManager moveItemAtPath:[deletedItem objectForKey:@"trashLocation"]
                            toPath:[deletedItem objectForKey:@"path"]
                             error:&error]) {
       if ([self.delegate respondsToSelector:@selector(updateDirectory:)] ) {
            [self.delegate updateDirectory:[[deletedItem objectForKey:@"path"] stringByDeletingLastPathComponent]];
        }
        [items removeObjectAtIndex:idx];
        [items writeToFile:dataFile atomically:YES];
    }
    else if (error) {
        NSAlert *alert = [NSAlert alertWithError:error];
        [alert runModal];
    }    
}
- (NSMenu *)restoreMenu {
    if ([items count] == 0)   return nil;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setDoesRelativeDateFormatting:YES];
    putBackMenu = [[NSMenu alloc] initWithTitle:@"Put Back Menu"];
    for (NSDictionary *deletedItem in items) {
        NSString *dateString = [dateFormatter stringFromDate:[deletedItem objectForKey:@"deletedDate"]];
        NSString *item = [NSString stringWithFormat:@"%@ deleted %@", [[deletedItem objectForKey:@"path"] lastPathComponent], dateString];
        [[putBackMenu addItemWithTitle:item action:@selector(putBackItem:) keyEquivalent:@""] setTarget:self];
    }
    return putBackMenu;
}

@end
