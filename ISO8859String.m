//
//  ISO8859String.m
//  Abstract: An NSData-backed string that treats each byte as a Unicode / ISO-8859-1 character.
//  If the character is a control character other than tab or newline, a Square is substituted.
//  The displayed characters are:-
//      Unicode Basic Latin, also called Basic Latin, 0020–007F (ASCII)
//      and Unicode Latin-1 Supplement, 00A0–00FF
//
//  Created by Ian Binnie on 26/06/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//
// The first 256 characters in Unicode and the UCS are identical to those in ISO/IEC-8859-1.

#import "ISO8859String.h"

@implementation ISO8859String
// Returns the character used to display the given byte in the resulting string.
static inline unichar displayCharacterForByte(unsigned char dataByte) {
    if ((dataByte >= 32 && dataByte < 127) ||
        (dataByte >= (128 + 32)) ||
        dataByte == '\n' ||
        dataByte == '\t') {
        return dataByte;
    } else {
        return 0x25fb;  // White Medium Square
    }
}

- (id)initWithData:(NSData *)obj {
    if (self = [super init]) {
        data = [obj copy];
    }
    return self;
}

- (id)init {
    return [self initWithData:[NSData data]];
}

- (NSData *)data {
    return data;
}

#pragma mark -

// Returns the length of the string, which is one Unicode character per byte.
- (NSUInteger)length {
    return [data length];
}

// Converts the byte at the given index to a displayable unichar
- (unichar)characterAtIndex:(NSUInteger)index {
    const unsigned char *bytes = [data bytes];
    
    return displayCharacterForByte(bytes[index]);
}

// Converts a range of bytes to displayable characters
// If the range is beyond the bounds of the data, an exception is thrown.
- (void)getCharacters:(unichar *)buffer range:(NSRange)range {
    const unsigned char *bytes = [data bytes];
    
    if (NSMaxRange(range) > [data length]) {
        @throw [NSException exceptionWithName:NSRangeException reason:[NSString stringWithFormat:@"*** -[%@ %@]: Range %@ is out of bounds", NSStringFromClass([self class]), NSStringFromSelector(_cmd), NSStringFromRange(range)] userInfo:nil];
    }
    
    NSUInteger i;
    for (i = 0; i < range.length; i++) {
        buffer[i] = displayCharacterForByte(bytes[range.location + i]);
    }
}

@end
