/*
     File: BaseNode.m 
 Abstract: Generic multi-use node object used with NSOutlineView and NSTreeController.
  
  Version: 1.1 
*/

#import "BaseNode.h"

@implementation BaseNode
static NSArray *leafNode = nil;
+ (void)initialize {
	leafNode = [NSArray array];
}
- (id)init {
	if (self = [super init]) {
		[self setNodeTitle:@"BaseNode Untitled"];
		[self setChildren:[NSMutableArray array]];
		[self setLeaf:NO];			// container by default
	}
	return self;
}

- (id)initLeaf {
	if (self = [self init]) {
		[self setLeaf:YES];
	}
	return self;
}

- (void)setLeaf:(BOOL)flag {
	isLeaf = flag;
	if (isLeaf)
		[self setChildren:[NSMutableArray arrayWithObject:leafNode]];
	else
		[self setChildren:[NSMutableArray array]];
}
- (BOOL)isLeaf {
	return isLeaf;
}

- (void)setPath:(NSString*)urlStr { 
    if (!nodePath || ![nodePath isEqualToString:urlStr]) {
		nodePath = urlStr; 
    }
}

- (NSString*)path { 
    return nodePath;
}


#pragma mark - Archiving And Copying Support

//	Override this method to maintain support for archiving and copying.
- (NSArray*)mutableKeys {
	return [NSArray arrayWithObjects:
		@"nodeTitle",
		@"isLeaf",		// isLeaf MUST come before children for initWithDictionary: to work
		@"children", 
		@"nodeIcon",
		@"nodePath",
		nil];
}

- (id)initWithCoder:(NSCoder*)coder {		
	self = [self init];
	NSEnumerator *keysToDecode = [[self mutableKeys] objectEnumerator];
	NSString *key;
	while (key = [keysToDecode nextObject])
		[self setValue:[coder decodeObjectForKey:key] forKey:key];
	
	return self;
}

- (void)encodeWithCoder:(NSCoder*)coder {	
	NSEnumerator *keysToCode = [[self mutableKeys] objectEnumerator];
	NSString *key;
	while (key = [keysToCode nextObject])
		[coder encodeObject:[self valueForKey:key] forKey:key];
}

- (id)copyWithZone:(NSZone*)zone {
	id newNode = [[[self class] allocWithZone:zone] init];
	
	NSEnumerator *keysToSet = [[self mutableKeys] objectEnumerator];
	NSString *key;
	while (key = [keysToSet nextObject])
		[newNode setValue:[self valueForKey:key] forKey:key];
	
	return newNode;
}

- (void)setNilValueForKey:(NSString*)key {
	if ([key isEqualToString:@"isLeaf"])
		isLeaf = NO;
	else
		[super setNilValueForKey:key];
}

@end
