//
//  DirectoryItem+Branch.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 15/11/12.
//
//

#import "DirectoryItem+Branch.h"
extern NSArray *fileSortDescriptor;

@interface DirectoryItem()
- (BOOL)isLeafNode;
@end

@implementation DirectoryItem (Branch)

void subBranch(NSArray *directories, NSMutableArray **fileArrayInBranch) {
    NSMutableArray *accumulatedFiles = *fileArrayInBranch;
    for (DirectoryItem *node in directories) {
        NSArray *filesInNode = node.files;
        if (filesInNode) {
            if (![accumulatedFiles containsObject:filesInNode])   // if not already in branch
                [accumulatedFiles addObject:filesInNode];
        }
        if(node.loggedSubDirectories)
			subBranch(node.loggedSubDirectories, fileArrayInBranch);
    }
}
- (NSMutableArray *)filesInBranch {
	NSMutableArray *fileArrayInBranch = [NSMutableArray new];
    if (self.files)    [fileArrayInBranch addObject:self.files];
	subBranch(self.loggedSubDirectories, &fileArrayInBranch);
	NSMutableArray *branch = [NSMutableArray new];
    for (NSArray *filesInNode in fileArrayInBranch) {
        [branch addObjectsFromArray:filesInNode];
    }
	[branch sortUsingDescriptors:fileSortDescriptor];
	return 	branch;
}

void loggedSubDirectoriesInBranch(DirectoryItem *source, NSMutableArray **accumulatedDirs) {
	[*accumulatedDirs addObjectsFromArray:source.loggedSubDirectories];
	for (DirectoryItem *dir in source.loggedSubDirectories) {
		loggedSubDirectoriesInBranch(dir, accumulatedDirs);
	}
}
- (NSArray *)directoriesInBranch {
	NSMutableArray *accumulated = [NSMutableArray new];
	loggedSubDirectoriesInBranch(self, &accumulated);
	return 	accumulated;
}

void logSubDirectoriesInBranch (DirectoryItem *source, NSMutableSet **accumulated) {
	if ([source isLeafNode])	return;
	[*accumulated addObject:source];
	NSArray *tempArray = [NSArray arrayWithArray:source.subDirectories];	// Loads subDirectories if not already loaded; Returns subDirectories
	for (DirectoryItem *dir in tempArray) {
		if ([*accumulated containsObject:dir]) continue;
		logSubDirectoriesInBranch(dir, accumulated);	// recursively add subDirectories to task
	}
}
- (void)logBranch {	// log all subdirectories in Branch
	NSMutableSet *accumulated = [NSMutableSet setWithCapacity:1000];
	logSubDirectoriesInBranch(self, &accumulated);
}
- (void)updateBranch {
	for (DirectoryItem *dir in self.directoriesInBranch) {
		[dir updateDirectory];
	}
}

@end
