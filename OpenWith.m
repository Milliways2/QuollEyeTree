//
//  OpenWith.m
//  QuollEyeTree
//
//  Created by Ian Binnie on 22/01/12.
//  Copyright 2012 Ian Binnie. All rights reserved.
//

#import "OpenWith.h"

@implementation OpenWith
@synthesize openWithMenu = _openWithMenu;

- (void)openInSelected:(id)sender {
	NSInteger idx = [_openWithMenu indexOfItem:sender];
	if(idx > 1) idx -= 2;
	NSURL *foundApp = [openWithApplications objectAtIndex:idx];
	NSArray *itemURLs = [NSArray arrayWithObject:urlToOpen];
	LSLaunchURLSpec inLaunchSpec;
	inLaunchSpec.appURL = (CFURLRef)foundApp;
	inLaunchSpec.itemURLs = (CFArrayRef)itemURLs;
	inLaunchSpec.passThruParams = NULL;
	inLaunchSpec.launchFlags = kLSLaunchDefaults;
	inLaunchSpec.asyncRefCon = NULL;
	LSOpenFromURLSpec(&inLaunchSpec, NULL);
}
- (void)openInDefault:(id)sender {
	LSOpenCFURLRef((CFURLRef)urlToOpen, nil);
}
- (id)initMenu:(NSURL *)url  {
	if(self = [super init]) {
		urlToOpen = url;
		_openWithMenu = [[NSMenu alloc] initWithTitle:@"Open With"];
		CFURLRef preferredApp;
		CFStringRef outDisplayName;
		OSStatus isPref = LSGetApplicationForURL((CFURLRef)url, kLSRolesAll, NULL, &preferredApp);
		if(isPref == kLSApplicationNotFoundErr) {
			[_openWithMenu addItemWithTitle:@"<None>" action:nil keyEquivalent:@""];
		}
		else {
			LSCopyDisplayNameForURL(preferredApp, &outDisplayName);
			NSMenuItem *mi = [_openWithMenu addItemWithTitle:(NSString *)outDisplayName action:@selector(openInDefault:) keyEquivalent:@""];
			[mi setTarget:self];
            CFRelease(outDisplayName);
            CFArrayRef apps = LSCopyApplicationURLsForURL((CFURLRef)url, kLSRolesAll);
			if(apps) {
				[_openWithMenu addItem:[NSMenuItem separatorItem]];
 				int i;
                NSURL *thisUrl;
                NSString *name;
                CFIndex appCount = CFArrayGetCount(apps);
                openWithApplications = [NSMutableArray arrayWithCapacity:appCount];
				for(i=0; i < appCount; i++) {
					CFURLRef thisApp = CFArrayGetValueAtIndex(apps, i);
                    if(CFEqual(thisApp, preferredApp))  continue;
                    thisUrl = (NSURL *)thisApp;
                    if (![[thisUrl path] hasPrefix:@"/Volumes"]) {
                        [openWithApplications addObject:thisUrl];
                        [thisUrl getResourceValue:&name forKey:NSURLLocalizedNameKey error:nil];
                        NSMenuItem *mi = [_openWithMenu addItemWithTitle:name action:@selector(openInSelected:) keyEquivalent:@""];
                        [mi setTarget:self];
                    }
				}
                CFRelease(apps);
			}
			CFRelease(preferredApp);
		}
	}
    return self;
}

@end
