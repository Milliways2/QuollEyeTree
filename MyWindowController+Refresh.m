//
//  MyWindowController+Refresh.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 2/10/11.
//  Copyright 2011 Ian Binnie. All rights reserved.
//

#import "MyWindowController+Refresh.h"
#import "DirectoryItem.h"
#import "volume.h"
#import "TreeViewController.h"

@implementation MyWindowController(Refresh)
static dispatch_queue_t refreshQueue;

void refreshDirectories(NSArray *dirs, TreeViewController *tvc) {
	dispatch_retain(refreshQueue);
	dispatch_async(refreshQueue, ^{
		for(DirectoryItem *node in dirs) {
			[node updateDirectory];
		}
		if(tvc)	[tvc reloadData];
		dispatch_release(refreshQueue);
	});
}

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[])
{
    MyWindowController *wc = (__bridge MyWindowController *)userData;
	NSMutableArray *dirsToRefresh = [[NSMutableArray alloc] initWithCapacity:numEvents];
	size_t i;
	for(i=0; i<numEvents; i++){
		DirectoryItem *node = findPathInVolumes([[(__bridge NSArray *)eventPaths objectAtIndex:i] stringByStandardizingPath]);
		if (node) {
			if ([node isPathLoaded]) {
				[dirsToRefresh addObject:node];	// Only if subDirectories loaded
			}
		}
	}
	if([dirsToRefresh count]) {
		refreshDirectories(dirsToRefresh, wc.currentTvc);
	}
}

- (void)initializeEventStream {
    NSArray *pathsToWatch = [NSArray arrayWithObject:[[[NSUserDefaults standardUserDefaults] stringForKey:PREF_REFRESH_DIR] stringByResolvingSymlinksInPath]];
    void *appPointer = (__bridge void *)self;
    FSEventStreamContext context = {0, appPointer, NULL, NULL, NULL};
    NSTimeInterval latency = 3.0;
	stream = FSEventStreamCreate(NULL,
	                             &fsevents_callback,
	                             &context,
	                             (__bridge CFArrayRef) pathsToWatch,
								 kFSEventStreamEventIdSinceNow,
	                             (CFAbsoluteTime) latency,
	                             kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagIgnoreSelf
								 );
	FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	FSEventStreamStart(stream);
	refreshQueue = dispatch_queue_create("au.id.binnie.refreshQueue", NULL);
}

- (void)startMonitoring {
	if([[NSUserDefaults standardUserDefaults] boolForKey:PREF_AUTOMATIC_REFRESH])
		[self initializeEventStream];
}
- (void)stopMonitoring {
    FSEventStreamStop(stream);
    FSEventStreamInvalidate(stream);
}
- (void)pauseMonitoring:(BOOL)pause {
	if (stream == nil) return;
	if (pause) {
        if (pauseCount++ == 0) {
            FSEventStreamStop(stream);
            [refresh startAnimation:self];
        }
        return;
    }
    if (pauseCount) {
        if (--pauseCount == 0) {
            FSEventStreamStart(stream);
            [refresh stopAnimation:self];
        }
    }
}

@end
