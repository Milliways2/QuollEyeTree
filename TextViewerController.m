//
//  TextViewController.m
//
//  Created by Ian Binnie on 24/06/12.
//  Copyright (c) 2012 Ian Binnie. All rights reserved.
//

#import "TextViewerController.h"
#import "MyTextView.h"
#include <sys/xattr.h>
#import "ISO8859String.h"
#import "SearchPanelController.h"

@implementation TextViewerController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}
- (void)showFound {
    if ([foundRanges count] == 0) return;
    NSRange rangeFound = [[foundRanges objectAtIndex:visibleIndex] rangeValue];
    [myTextView setSelectedRange:rangeFound];
    [myTextView scrollRangeToVisible:rangeFound];
    [myTextView showFindIndicatorForRange:rangeFound];
}
- (void)searchAgain {
    NSDictionary *foundTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                         [NSColor blueColor], NSForegroundColorAttributeName,
                                         nil];
    if(_searchString == NULL)    return;
    NSString *dataString = [[myTextView textStorage] string];
	NSRange textCharRange = {0, [dataString length]};	// Original string
    [[myTextView layoutManager] removeTemporaryAttribute:NSForegroundColorAttributeName forCharacterRange:textCharRange];  
    foundRanges = [NSMutableArray new];
    NSStringCompareOptions opt = (_regexSearch ? NSRegularExpressionSearch : 0) | (_caseSensitive ? 0 : NSCaseInsensitiveSearch);
	NSRange rangeFound = [dataString rangeOfString:_searchString options:opt range:textCharRange];
    while (rangeFound.length != 0) {
        [foundRanges addObject:[NSValue valueWithRange:rangeFound]];
        [[myTextView layoutManager] addTemporaryAttributes:foundTextAttributes forCharacterRange:rangeFound];   
        textCharRange.location = NSMaxRange(rangeFound);
        textCharRange.length = [dataString length] - NSMaxRange(rangeFound);
        rangeFound = [dataString rangeOfString:_searchString options:opt range:textCharRange];
    }
    visibleIndex = 0;
    [self showFound];
}
- (void)searchFirst:(NSString *)searchString regexSearch:(BOOL)regexSearch caseSensitive:(BOOL)caseSensitive {
    _searchString = searchString;
    _regexSearch = regexSearch;
    _caseSensitive = caseSensitive;
    [self searchAgain];
}
static NSStringEncoding encodingForPath(NSString *path) {
    char value[128];
    ssize_t dsize = getxattr([path UTF8String], "com.apple.TextEncoding", &value, sizeof(value), 0, 0);
    if (dsize > 0) {
        char *encoding = value;
        strsep(&encoding, ",;");  // skip com.apple.TextEncoding name
        return CFStringConvertEncodingToNSStringEncoding (atoi(encoding));
    }
    return 0;
}
// Heuristic encoding based on BOM or analysis of bytes
static NSStringEncoding encodingForData(NSData *data) {
    const unsigned char *dataBytes = [data bytes];
    if(bcmp(dataBytes, "\xEF\xBB\xBF" ,3) == 0)  return NSUTF8StringEncoding;
    if(bcmp(dataBytes, "\xFE\xFF" ,2) == 0)  return NSUTF16BigEndianStringEncoding;
    if(bcmp(dataBytes, "\xFF\xFE" ,2) == 0)  return NSUTF16LittleEndianStringEncoding;
    
    NSUInteger even = 0, odd = 0, be = 0, le = 0, high = 0, length = [data length];
    for (int i = 0; i < length/2; i++) {
        if(bcmp(dataBytes, "\x00\x0d" ,2) == 0)  be++;
        if(bcmp(dataBytes, "\x00\x0a" ,2) == 0)  be++;
        if(bcmp(dataBytes, "\x0d\x00" ,2) == 0)  le++;
        if(bcmp(dataBytes, "\x0a\x00" ,2) == 0)  le++;
        if (*dataBytes > 0x7f) high++;
        if (*dataBytes++ == 0) odd++;
        if (*dataBytes > 0x7f) high++;
        if (*dataBytes++ == 0) even++;
    }
    if (high == 0) return NSASCIIStringEncoding;
    if(le == 0 && be > 1)   return NSUTF16BigEndianStringEncoding;
    if(be == 0 && le > 1)   return NSUTF16LittleEndianStringEncoding;
    if(be == 0 && le == 0) {
        if((odd * 3 > length) && (even * 5 < length))   return NSUTF16BigEndianStringEncoding;
        if((even * 3 > length) && (odd * 5 < length))   return NSUTF16LittleEndianStringEncoding;
    }
    return 0;
}

- (id)initWithData:(NSData *)data encoding:(NSStringEncoding)enc {
    NSString *dataString;
    if (enc == 0)   enc = encodingForData(data);
    if (enc == 0)   enc = NSUTF8StringEncoding;    // try UTF-8
    dataString = [[NSString alloc] initWithData:data encoding:enc];
    if (dataString == nil) {
        enc = NSWindowsCP1252StringEncoding;    // try CP1252
        dataString = [[NSString alloc] initWithData:data encoding:enc];
    }
    if (dataString == nil) {
        dataString = [[ISO8859String alloc] initWithData:data];
    }
    
    // Set up data storage
    NSMutableParagraphStyle *myPara = [[NSMutableParagraphStyle alloc] init];
    [myPara setParagraphStyle:[NSParagraphStyle defaultParagraphStyle]];
	//    [myPara setLineBreakMode:NSLineBreakByTruncatingTail];
	//    [myPara setLineBreakMode:NSLineBreakByClipping];
    [myPara setDefaultTabInterval:8.0];
    NSDictionary *plainTextAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
//                                         [NSFont userFixedPitchFontOfSize:12.0], NSFontAttributeName,
                                         [NSFont fontWithName:@"Menlo" size:12], NSFontAttributeName,
                                         myPara, NSParagraphStyleAttributeName,
                                         nil];
    
    NSTextStorage *myStorage = [[NSTextStorage alloc] initWithString:dataString attributes:plainTextAttributes];
    [[myTextView layoutManager] replaceTextStorage:myStorage];
// disable word wrap
//    [[myTextView textContainer] setContainerSize:NSMakeSize(FLT_MAX, FLT_MAX)];
//    [[myTextView textContainer] setWidthTracksTextView:NO];
//    [myTextView setHorizontallyResizable:YES];
	return self;
}
- (id)initWithPath:(NSString *)path {
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	if (fileHandle == nil) return nil;
//    NSError *error;
//    if (!fileHandle) error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:[NSDictionary dictionaryWithObjectsAndKeys:path, NSURLErrorKey, nil]];
    NSData *data = [fileHandle readDataOfLength:MAX_TEXT_FILE];
    [fileHandle closeFile];
    fileHandle = nil;
    [self.fileName setStringValue:[path lastPathComponent]];
    NSStringEncoding enc = 0;
    enc = encodingForPath(path);
	return [self initWithData:data encoding:enc];
}

- (void)findAfter:(NSUInteger)location {
    for (NSUInteger indx = 0; indx < [foundRanges count]; indx++) {
        NSRange rangeFound = [[foundRanges objectAtIndex:indx] rangeValue];
        if (rangeFound.location >= location) {
            visibleIndex = indx;
            return;
        }
    }
}
- (void)showNext {
    NSUInteger numberFound = [foundRanges count];
    if (numberFound == 0) return;
    if(NSLocationInRange ([[foundRanges objectAtIndex:visibleIndex] rangeValue].location, [myTextView visibleRange])) {
        if (numberFound - 1 > visibleIndex)  visibleIndex++;    // next
        else    [self findAfter:[myTextView visibleRange].location];    // find 1st after startOfScreen
    }
    [self showFound];
}
- (void)showNextScreen {
    NSUInteger numberFound = [foundRanges count];
    if (numberFound == 0) return;
    [self findAfter:NSMaxRange([myTextView visibleRange])];    // find 1st after endOfScreen
    [self showFound];
}
- (void)findBefore:(NSUInteger)location {
    for (NSInteger indx = [foundRanges count] - 1 ; indx >= 0; indx--) {
        NSRange rangeFound = [[foundRanges objectAtIndex:indx] rangeValue];
        if (rangeFound.location < location) {
            visibleIndex = indx;
            return;
        }
    }
}
- (void)showPrevious {
    NSUInteger numberFound = [foundRanges count];
    if (numberFound == 0) return;
    if(NSLocationInRange([[foundRanges objectAtIndex:visibleIndex] rangeValue].location, [myTextView visibleRange])) {
        if (visibleIndex > 0)   visibleIndex--;    // previous 
        else    [self findBefore:NSMaxRange([myTextView visibleRange])];    // find last before endOfScreen
    }
    [self showFound];
}
- (void)showPreviousScreen {
    NSUInteger numberFound = [foundRanges count];
    if (numberFound == 0) return;
    [self findBefore:[myTextView visibleRange].location];    // find last before startOfScreen 
    [self showFound];
}
#ifdef PREVIOUS_RELEASE
BOOL lionSupport(void) {
    SInt32 major, minor;
    Gestalt(gestaltSystemVersionMajor, &major);
    Gestalt(gestaltSystemVersionMinor, &minor);
    if(major>=10 &&  minor>=7) return YES;
    return NO;
}
#endif

- (BOOL)keyPressedInTextView:(NSEvent *)theEvent {
	unichar keyChar = [[theEvent charactersIgnoringModifiers] characterAtIndex:0];
	if ([theEvent modifierFlags] & NSCommandKeyMask) {
        if (keyChar == 'a') {
            [myTextView doCommandBySelector:@selector(selectAll:)];
            return YES;
        }
		return YES;
	}
    if (keyChar == 0x1b) {
        if([self.delegate respondsToSelector:@selector(exitTextView:)])
            [self.delegate exitTextView:self];
		return YES;
	}
    if (keyChar == 'f') {
        SearchPanelController *searchPanel = [SearchPanelController singleton];
#ifdef PREVIOUS_RELEASE
       [searchPanel allowRegex:lionSupport()];
#else
		[searchPanel allowRegex:YES];
#endif
        if ([searchPanel runModal] == NSOKButton) {
            if(searchPanel.searchString)
                [self searchFirst:searchPanel.searchString regexSearch:searchPanel.regexSearch caseSensitive:searchPanel.isCaseSensitive];
        }
		return YES;
	}
    if (keyChar == '+') {
        [self showNext];
		return YES;
	}
    if (keyChar == '-') {
        [self showPrevious];
		return YES;
	}
    if (keyChar == '>') {
        [self showNextScreen];
		return YES;
	}
    if (keyChar == '<') {
        [self showPreviousScreen];
		return YES;
	}
   if (keyChar == 'n') {
        if([self.delegate respondsToSelector:@selector(nextFile:)]) {
            [myTextView setSelectedRange:NSMakeRange(0,0)];
            [self.delegate nextFile:self];
            [self searchAgain];
        }
		return YES;
	}
    if (keyChar == 'p') {
        if([self.delegate respondsToSelector:@selector(previousFile:)]) {
            [myTextView setSelectedRange:NSMakeRange(0,0)];
            [self.delegate previousFile:self];
            [self searchAgain];
        }
		return YES;
	}
	return NO;
}

@end
