//
//  BRBasePdfPageView.m
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRBasePdfPageView.h"

#import "BRPdfDrawingUtils.h"
#import "BRScrollerLogging.h"

@implementation BRBasePdfPageView {
	CGPDFDocumentRef doc;
	CGPDFPageRef page;
	NSUInteger pageIndex;
}

@synthesize page, pageIndex;

- (id)initWithFrame:(CGRect)frame {
	if ( (self = [super initWithFrame:frame]) ) {
		page = NULL;
		doc = NULL;
		pageIndex = 0;
	}
	return self;
}

- (void)dealloc {
	self.page = NULL; // also sets doc to NULL
}

- (CGSize)sizeThatFits:(CGSize)toFit {
	@synchronized(self) {
		if ( page == NULL ) {
			return toFit;
		}
		CGSize pdfSize = [self naturalSize];
		return 	BRScrollerAspectSizeToFit(pdfSize, toFit);
	}
}

- (CGSize)naturalSize {
	return BRScrollerPdfNaturalSize(page);
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@{page=%lu}", NSStringFromClass([self class]), (unsigned long)pageIndex];
}

#pragma mark Protected API

- (void)drawInRect:(CGRect)rect context:(CGContextRef)context {
	if ( page == NULL || self.hidden ) {
		return;
	}
	DDLogVerbose(@"Drawing page %lu to %@", (unsigned long)pageIndex, NSStringFromCGRect(rect));
	
	// This method could be called from a CATiledLayer background thread.
	// For thread safety, we need to synchronize with the main thread which might try to change the page
	// while we're trying to draw. We don't want to block the main thread for the entire time it takes to
	// draw, however, so we only synchronize around getting locally retained references to our PDF page/document
	// which won't take long... then we can leave the synchronized block and perform the actual drawing safely.
	
	CGPDFDocumentRef localDoc;
	CGPDFPageRef localPage;
	@synchronized(self) {
		localPage = CGPDFPageRetain(page);
		localDoc = CGPDFDocumentRetain(CGPDFPageGetDocument(localPage));
	}
	BRScrollerPdfDrawPage(localPage, rect, self.backgroundColor.CGColor, context, true);
	CGPDFPageRelease(localPage);
	CGPDFDocumentRelease(localDoc);
}

- (void)pdfPageDidChange {
	[self setNeedsDisplay];
}

- (void)pdfDocumentDidChange {
	// extending classes may use
}

- (void)setBounds:(CGRect)bounds {
	[super setBounds:bounds];
	DDLogDebug(@"Page %lu bounds set to %@", (unsigned long)pageIndex, NSStringFromCGRect(bounds));
}

#pragma mark Accessors

- (void)setDoc:(CGPDFDocumentRef)theDocument {
	if ( doc != theDocument ) {
		CGPDFDocumentRef oldDoc = CGPDFDocumentRetain(doc);
		CGPDFDocumentRelease(doc);
		doc = CGPDFDocumentRetain(theDocument);
		CGPDFDocumentRelease(oldDoc);
		[self pdfDocumentDidChange];
	}
}

- (void)setPage:(CGPDFPageRef)thePage {
	if ( page != thePage ) {
		CGPDFPageRef old = CGPDFPageRetain(page);
		@synchronized(self) {
			CGPDFPageRelease(page);
			page = CGPDFPageRetain(thePage);
			
			// we also retain/release the page's owning document, to prevent crashes related
			// to using a CGPDFPageRef after it's owning CGPDFDocumentRef has been released
			[self setDoc:CGPDFPageGetDocument(page)];
		}
		[self pdfPageDidChange];
		CGPDFPageRelease(old);
	}
}

@end
