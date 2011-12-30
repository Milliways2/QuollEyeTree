//
//  IBPathPopUpButton.m
//  PathChooser Test
//
//  Created by Ian Binnie on 6/05/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "IBPathPopUpButton.h"
#import "PathHelper.h"
@interface IBPathPopUpButton()
- (void)updateModel:(NSString *)path;
@end

@implementation IBPathPopUpButton
@synthesize popupPath;
#define kIconImageSize		16.0

#pragma mark  Private Methods
- (void)clearPopUpPath {
    if (userSelectedPath) {
        userSelectedPath = nil;
        NSInteger numItems = [self numberOfItems] - 4;
        [self removeItemAtIndex:numItems];
        [self removeItemAtIndex:numItems];
     }
}
- (void)insertPopUpPath:(NSString *)path {
    [self clearPopUpPath];
    userSelectedPath = path;
    NSInteger numItems = [self numberOfItems] - 2;
    [self insertItemWithTitle:[[path lastPathComponent] stringByAppendingString:@" "] atIndex:numItems];
    NSImage *iconImage = [[PathHelper sharedPathHelper] iconForPath:path];
    [iconImage setSize:NSMakeSize(kIconImageSize, kIconImageSize)];
    NSMenuItem *item = [self itemAtIndex:numItems];
    [item setImage:iconImage];        
    [item setTarget:self];
    [item setAction:@selector(selectUserDirectory:)];
    [[self menu] insertItem:[NSMenuItem separatorItem] atIndex:numItems];
    [self selectItem:item];
    indexSelected = [self indexOfSelectedItem];
    self.popupPath = path;
    [self updateModel:path];
}
#pragma mark  Selectors
- (void)selectUserDirectory:(id)sender {
    // Other directory re-selected - do nothing
}
- (void)selectStandardDirectory:(id)sender {
    NSString *newValue = [[PathHelper sharedPathHelper] pathForName:[sender titleOfSelectedItem]];
    self.popupPath = newValue;
    indexSelected = [self indexOfSelectedItem];
    [self clearPopUpPath];
    [self updateModel:newValue];
}
- (void)selectOtherDirectory:(id)sender {
    // NSOpenPanel to choose Path
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];    
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanCreateDirectories:NO];
    [openPanel setPrompt:@"Choose folder"];
    [openPanel setCanChooseFiles:NO];
	NSInteger result = [NSApp runModalForWindow:openPanel];
    if(result == NSOKButton) {
        [self insertPopUpPath:[[[openPanel URLs] objectAtIndex:0] path]];
    }
    else
        [self selectItemAtIndex:indexSelected]; // just keep position
}
#pragma mark  Setup
- (void)initPopUpMenu {
    [self setTarget:self];
    [self setAction:@selector(selectStandardDirectory:)];
    NSArray *goPlaces;
    goPlaces = [NSArray arrayWithObjects:
                @"Home",
                @"Documents",
                @"Desktop",
                @"Downloads",
                @"Users",
                nil];
    PathHelper *pathHelper = [PathHelper sharedPathHelper];
    NSMenuItem *item;
    NSImage *iconImage;
    for (NSString *place in goPlaces) {
        [self addItemWithTitle:place];
        item = [self lastItem];
        iconImage = [pathHelper iconForName:place];
        [iconImage setSize:NSMakeSize(kIconImageSize, kIconImageSize)];
        [item setImage:iconImage];        
    }
    [[self menu] addItem:[NSMenuItem separatorItem]];
    [self addItemWithTitle:@"Other..."];
    item = [self itemWithTitle:@"Other..."];
    [item setTarget:self];
    [item setAction:@selector(selectOtherDirectory:)];
}
- (void)awakeFromNib {
    [self initPopUpMenu];
}
// locate and select Standard Directory or insert User Directory
- (void)initialisePopUpPath:(NSString *)path {
    NSString *newPath = [path stringByExpandingTildeInPath];
    NSInteger numItems = [self numberOfItems] - 2;
    PathHelper *pathHelper = [PathHelper sharedPathHelper];
    NSString *menuPath;
    for (NSInteger index=0; index<numItems; index++) {
        menuPath = [pathHelper pathForName:[self itemTitleAtIndex:index]];
        if ([newPath caseInsensitiveCompare:menuPath] == NSOrderedSame) {
            [self selectItemAtIndex:index];
            indexSelected = index;
            self.popupPath = menuPath;
            return;
        }
    }
    [self insertPopUpPath:newPath];
}
#pragma mark  Bindings
static void *PathBindingContext = (void *)@"PathCtxt";

- (void)bind:(NSString *)binding
    toObject:(id)observableObject
 withKeyPath:(NSString *)keyPath
     options:(NSDictionary *)options {
    if ([binding isEqualToString:@"popupPath"])
    {
        // Observe the observableObject for changes 
        // pass binding identifier as the context, so you get that back in observeValueForKeyPath:...
        [observableObject addObserver:self
                           forKeyPath:keyPath
                              options:0
                              context:PathBindingContext];
        // Register what object and keypath are associated with this binding
        observedObjectForPath = observableObject;
        observedKeyPathForPath = [keyPath copy];
        // set initial value from model
        id newValue = [observedObjectForPath valueForKeyPath:observedKeyPathForPath];
        [self initialisePopUpPath:newValue];
    }
}
// Model-Initiated Update
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    // the binding identifier passed as the context when registering as an observer
    if (context == PathBindingContext) {
        NSString *newPath = [[observedObjectForPath valueForKeyPath:observedKeyPathForPath] stringByExpandingTildeInPath];
        if ([newPath caseInsensitiveCompare:popupPath] == NSOrderedSame)  return; // avoid loop
        [self initialisePopUpPath:newPath];
    }
}
// View-Initiated Updates
- (void)updateModel:(NSString *)path {
    if (observedObjectForPath != nil) {
        [observedObjectForPath setValue:path forKeyPath:observedKeyPathForPath];
    }
}


@end
