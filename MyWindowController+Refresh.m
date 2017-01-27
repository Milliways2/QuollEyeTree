//
//  MyWindowController+Refresh.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 2/10/11.
//  Copyright 2011-2015 Ian Binnie. All rights reserved.
//

#import "MyWindowController+Refresh.h"
#import "DirectoryItem.h"
#import "volume.h"
#import "TreeViewController.h"

@implementation MyWindowController(Refresh)

static NSOperationQueue *queue;

/*! @brief	Called if there are loaded Directories requiring refresh
 @param	dirs an array of loaded Directories requiring refresh
 @param	wc MyWindowController
*/
//void refreshDirectories(NSArray *dirs, TreeViewController *tvc) {
//	NSLog(@"refreshDirectories");
//	if(queue == NULL) {
//		queue = [NSOperationQueue new];
//		[queue setMaxConcurrentOperationCount:10];
//	}
//	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
//		for(DirectoryItem *node in dirs) {
//			[node updateDirectory];
//		}
//	}];
//	[op setCompletionBlock:^{
//		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
//			if(tvc)	[tvc reloadData];
//		}];
//	}];
//	[queue addOperation:op];
//}
void refreshDirectories(NSArray *dirs, MyWindowController *wc) {
	if(queue == NULL) {
		queue = [NSOperationQueue new];
		[queue setMaxConcurrentOperationCount:10];
	}
	NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
		FSEventStreamStop(wc->stream);	//2016-05-07
		for(DirectoryItem *node in dirs) {
			[node updateDirectory];
		}
	}];
	[op setCompletionBlock:^{
		[[NSOperationQueue mainQueue] addOperationWithBlock:^{
			TreeViewController *tvc = wc->currentTvc;
			if(tvc)	[tvc reloadData];
			FSEventStreamStart(wc->stream);	//2016-05-07
		}];
	}];
	[queue addOperation:op];
}

//http://stackoverflow.com/questions/12507193/coreanimation-warning-deleted-thread-with-uncommitted-catransaction

// FSEventStreamCallback which will be called when FS events occur
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
//		refreshDirectories(dirsToRefresh, wc.currentTvc);
		refreshDirectories(dirsToRefresh, wc);	//2016-05-08
	}
}

/*! @brief	This is a (private) method to initiate watch for modifications on a nominated directory
 @internal
 */
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
