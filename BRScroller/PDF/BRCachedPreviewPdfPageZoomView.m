//
//  BRCachedPreviewPdfPageZoomView.m
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRCachedPreviewPdfPageZoomView.h"

@implementation BRCachedPreviewPdfPageZoomView {
	BRCachedPreviewPdfPageView *pdfView;
}

@synthesize pdfView;

- (id)initWithFrame:(CGRect)theFrame {
	if ( (self = [super initWithFrame:theFrame]) ) {
		self.pdfView = [[BRCachedPreviewPdfPageView alloc] initWithFrame:theFrame];
		pdfView.pageView.snapshotOnRefresh = YES;
		self.minimumZoomScale = 1.0;
		self.maximumZoomScale = 4.0;
		self.scrollEnabled = YES;
	}
	return self;
}

- (void)setPdfView:(BRCachedPreviewPdfPageView *)theView {
	if ( pdfView != theView ) {
		[pdfView removeFromSuperview];
		pdfView = theView;
		if ( pdfView != nil ) {
			[self addSubview:pdfView];
			self.contentOffset = CGPointZero;
		}
	}
}

- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	[pdfView setNeedsDisplay];
}

- (void)setPage:(CGPDFPageRef)page forIndex:(NSUInteger)pageIndex withKey:(NSString *)key {
	// this method is called directly by view controllers, to tell us we've "reset" to new content,
	// and as such we go back to our initial, non-zoomed view positioned at the top of the first page
	[pdfView updateContentWithPage:page atIndex:pageIndex withKey:key];
	CGSize size = [pdfView sizeThatFits:self.bounds.size];
	pdfView.bounds = CGRectMake(0, 0, size.width, size.height);
	pdfView.center = CGPointMake(size.width / 2.0, size.height / 2.0);
	pdfView.transform = CGAffineTransformIdentity;
	
	[self setZoomScale:1.0 animated:NO];
	self.contentSize = size;
	self.contentOffset = CGPointZero;
	
	// immediately layout page, so happens within current animation transaction and we avoid a "stretching" effect
	[pdfView layoutSubviews];
	[self layoutSubviews];
}

#pragma mark UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)theScrollView {
	return pdfView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
	[super scrollViewDidEndZooming:scrollView withView:view atScale:scale];
	if ( pdfView.pageView.snapshotOnRefresh &&  pdfView.pageView.snapshotCacheEnabled ) {
		// need to redraw snapshots while zooming
		[pdfView setNeedsDisplayInRect:[pdfView convertRect:scrollView.bounds fromView:scrollView]];
	}
}

@end
