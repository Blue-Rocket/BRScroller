//
//  BRCachedPreviewPdfPageView.m
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRCachedPreviewPdfPageView.h"

#import "BRPdfDrawingUtils.h"
#import "BRScrollerLogging.h"

@implementation BRCachedPreviewPdfPageView {
	CGSize previewSize;
	CGFloat previewFadeDuration;
	BRTiledPdfPageView *pageView;
	id<BRImageRenderService> previewService;
	BOOL previewDisabled;
	UIView *previewView;
	NSString *key;
}

@synthesize previewSize, pageView;
@synthesize previewService;
@synthesize previewDisabled;
@synthesize key;

- (id)initWithFrame:(CGRect)frame {
	if ( (self = [super initWithFrame:frame]) ) {
		previewSize = [self defaultPreviewSize];
		previewView = [self newPreviewView];
		previewFadeDuration = 0.2;
		previewDisabled = NO;
		[self addSubview:previewView];
		self.pageView = [[BRTiledPdfPageView alloc] initWithFrame:frame];
		pageView.hidden = YES;
	}
	return self;
}

- (CGSize)defaultPreviewSize {
	UIScreen *screen = [UIScreen mainScreen];
	CGSize screenSize = screen.bounds.size;
	CGFloat max = MAX(screenSize.width, screenSize.height) * 0.8 * screen.scale;
	return CGSizeMake(max, max);
}

- (UIView *)newPreviewView {
	UIView *view = [[UIView alloc] initWithFrame:self.bounds];
	view.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
	view.opaque = NO;
	return view;
}

- (void)dealloc {
	pageView.drawDelegate = nil;
	pageView = nil;
	previewView = nil;
	//previewService = nil;
}

#pragma mark Setters

- (void)setPreviewDisabled:(BOOL)disabled {
	if ( disabled != previewDisabled ) {
		previewDisabled = disabled;
		if ( disabled ) {
			// pageView is initialized to hidden, so ensure not hidden here if disable previews
			pageView.hidden = NO;
		}
	}
}

- (void)setPageView:(BRTiledPdfPageView *)thePageView {
	if ( thePageView != pageView ) {
		pageView.drawDelegate = nil;
		pageView = thePageView;
		pageView.frame = self.bounds;
		[self addSubview:pageView];
	}
}

#pragma mark Layout

- (CGSize) sizeThatFits:(CGSize)toFit {
	return [pageView sizeThatFits:toFit];
}

- (void)setNeedsLayout {
	[super setNeedsLayout];
	[pageView setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	DDLogDebug(@"Layout subviews of view %@ to %@", self, NSStringFromCGRect(self.bounds));
	CGRect bounds = self.bounds;
	if ( CGSizeEqualToSize(previewView.bounds.size, bounds.size) == NO ) {
		previewView.frame = bounds;
	}
	CGSize pageViewSize = CGSizeApplyAffineTransform(pageView.bounds.size, pageView.transform);
	if ( CGSizeEqualToSize(pageViewSize, bounds.size) == NO ) {
		
		// Discovered a nifty trick with CATiledLayer, in that if you change the transform when resizing
		// the view, instead of the bounds, it does not re-draw and flash on the screen. So, if the size
		// has changed, but is an aspect-scaled size change, just change the transform on the view to match
		// the new scale. Otherwise set the bounds to match so that future size changes (i.e. from
		// orientation changes) can just apply the transform instead of changing the view bounds.
		
		CGSize scaledSize = BRScrollerAspectSizeToFit(pageView.bounds.size, bounds.size);
		CGFloat dw = scaledSize.width - bounds.size.width;
		CGFloat dh = scaledSize.height - bounds.size.height;
		
		// at this point, dw and dh ideally are 0, but they might be off by 1 due to rounding
		if ( ABS(dw) < 3.0 && ABS(dh) < 3.0 ) {
			pageView.transform = CGAffineTransformMakeScale(bounds.size.width / pageView.bounds.size.width,
															bounds.size.height / pageView.bounds.size.height);
		} else {
			// just set frame so our aspect size matches, then we later adjust via transforms
			pageView.transform = CGAffineTransformIdentity;
			pageView.bounds = bounds;
		}
	}
	CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
	if ( CGPointEqualToPoint(pageView.center, center) == NO ) {
		pageView.center = center;
	}
}

#pragma mark Drawing

- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	// pass to PDF view
	[pageView setNeedsDisplay];
}

- (void)setNeedsDisplayInRect:(CGRect)rect {
	[super setNeedsDisplayInRect:rect];
	
	// pass to PDF view
	CGRect subviewRect = CGRectIntegral([pageView convertRect:rect fromView:self]);
	[pageView setNeedsDisplayInRect:subviewRect];
}

- (NSString *)previewImageKey {
	NSString *extension = [key pathExtension];
	NSString *base = [key stringByDeletingPathExtension];
	return [NSString stringWithFormat:@"%@-%lu-%dx%d.%@", base, (unsigned long)pageView.pageIndex, (int)previewSize.width, (int)previewSize.height,
			([extension length] > 0 ? extension : @"png")];
}

- (void)updateContentWithPage:(CGPDFPageRef)pdfPage atIndex:(NSUInteger)pageIndex withKey:(NSString *)imageKey {
	if ( pdfPage == pageView.page ) {
		// already set to same, don't set again
		DDLogDebug(@"Page %lu already set on %@", (unsigned long)pageIndex, self);
		return;
	}
	
	pageView.pageIndex = pageIndex;
	pageView.page = pdfPage;
	key = imageKey;
	
	// remove any transform applied by layoutSubviews, as we get better rendering of snapshots
	// when no transform on the view is involved.
	pageView.transform = CGAffineTransformIdentity;
	pageView.frame = self.bounds;
	previewView.frame = self.bounds;
	
	[self setNeedsDisplay];
	if ( previewDisabled == NO ) {
		pageView.layer.hidden = YES;
		
		// without this transaction, we get an implicit fade-out of the existing content, which during
		// view re-cycling causes an unwanted cross-fade effect between the old contents and the new image
		// set later in drawPreviewImage:
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		previewView.layer.contents = nil;
		[CATransaction commit];
		
		// draw preview
		NSUInteger index = pageView.pageIndex;
		CGSize maxSize = self.previewSize;
		
		[previewService imageForKey:[self previewImageKey] context:nil
					   renderedWith:^UIImage * _Nonnull(NSString * _Nonnull key, id _Nonnull context) {
			CGSize pdfSize = BRScrollerPdfNaturalSize(pdfPage);
			CGSize fitSize = BRScrollerAspectSizeToFit(pdfSize, maxSize);
			CGContextRef bitmapContext = BRScrollerCreateBitmapContextNoAlpha(fitSize);
			CGContextSetInterpolationQuality(bitmapContext, kCGInterpolationHigh);
			CGRect drawRect = CGRectMake(0, 0, fitSize.width, fitSize.height);
			BRScrollerPdfDrawPage(pdfPage, drawRect, [UIColor whiteColor].CGColor, bitmapContext, false);
			CGImageRef outputImageRef = CGBitmapContextCreateImage(bitmapContext);
			return [UIImage imageWithCGImage:outputImageRef];
		} confirmWith:^BOOL(NSString * _Nonnull confirmKey, id  _Nonnull context) {
			return [confirmKey isEqualToString:[self previewImageKey]];
		} handler:^(NSString * _Nonnull key, id  _Nonnull context, UIImage *  _Nonnull image) {
			[self drawPreviewImage:image.CGImage forPage:index];
		}];
	}
}

- (void)drawPreviewImage:(CGImageRef)image forPage:(NSUInteger)index {
	DDLogDebug(@"Drawing %lu preview %@ to layer size %@ (view size %@)", (unsigned long)index,
			  NSStringFromCGSize(CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image))),
			  NSStringFromCGSize(previewView.bounds.size),
			  NSStringFromCGSize(self.bounds.size));
	// this may not be the main thread... so no UIKit here
	if ( previewView != nil && index == pageView.pageIndex && previewView.layer.contents == nil ) {
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		previewView.layer.contents = (__bridge id)image;
		if ( previewFadeDuration > 0.0 ) {
			previewView.layer.opacity = 0.0;
		}
		[CATransaction commit];
		if ( previewFadeDuration > 0.0 ) {
			[CATransaction begin];
			// fade in to smooth out the transition, after fade show tiled layer
			[CATransaction setAnimationDuration:previewFadeDuration];
			previewView.layer.opacity = 1.0;
			[CATransaction setCompletionBlock:^(void) {
				pageView.layer.hidden = NO;
			}];
			[CATransaction commit];
		} else {
			// no fade, just blast everything on immediately
			pageView.layer.hidden = NO;
		}
	}
}

@end
