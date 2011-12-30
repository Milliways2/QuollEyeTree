//
//  ISO8859String.h
//  TextViewer
//
//  Created by Ian Binnie on 26/06/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ISO8859String : NSString {
NSData *data;
}
- (id)initWithData:(NSData *)obj;
- (NSData *)data;

@end
