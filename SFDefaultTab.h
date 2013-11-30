//
//  SFDefaultTab.h
//  tabtest
//
//  Created by Matteo Rattotti on 2/28/10.
//  Copyright 2010 www.shinyfrog.net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "SFTabView.h"

@interface SFLabelLayer : CATextLayer {}
@end

@interface SFDefaultTab : CALayer {
    id _representedObject;
}

- (void)setRepresentedObject: (id) representedObject;
- (void)setSelected: (BOOL)selected;

@end
