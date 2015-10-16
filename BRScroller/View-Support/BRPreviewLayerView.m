//
//  BRPreviewLayerView.m
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRPreviewLayerView.h"

#import <QuartzCore/QuartzCore.h>

#import "BRScrollerLogging.h"
#import "BRScrollerUtilities.h"

static NSString * const kPreviewKey = @"BR.imageKey";

@implementation BRPreviewLayerView {
	CGSize previewSize;
	CGFloat previewFadeDuration;
	BOOL previewDisabled;
	CALayer *previewLayer;
	UIView *contentView;
	__weak id<BRPreviewLayerViewDelegate> delegate;
}

@synthesize contentView;
@synthesize delegate;
@synthesize previewDisabled;
@synthesize previewSize;

- (id)initWithFrame:(CGRect)frame {
    if ( (self = [super initWithFrame:frame]) ) {
        previewLayer = [self newPreviewLayer];
		previewFadeDuration = 0.2;
		previewDisabled = NO;
		previewSize = CGSizeMake(320, 640);
		[self.layer addSublayer:previewLayer];
    }
    return self;
}

- (CALayer *)newPreviewLayer {
	CALayer *layer = [[CALayer alloc] init];
	layer.bounds = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
	layer.position = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
	layer.anchorPoint = CGPointMake(0.5, 0.5);
	return layer;
}

#pragma mark - Accessors

- (void)setPreviewDisabled:(BOOL)disabled {
	if ( disabled != previewDisabled ) {
		previewDisabled = disabled;
		if ( disabled ) {
			contentView.hidden = NO;
		}
	}
}

- (void)setContentView:(UIView *)theContentView {
	if ( theContentView != contentView ) {
		[contentView removeFromSuperview];
		contentView = theContentView;
		if ( contentView != nil ) {
			contentView.frame = self.bounds;
			[self addSubview:contentView];
		}
	}
}

#pragma mark Layout

- (CGSize)sizeThatFits:(CGSize)toFit {
	CGSize contentSize = (previewLayer.contents != nil ? previewLayer.bounds.size : [contentView sizeThatFits:toFit]);
	CGSize aspectFitSize = BRAspectSizeToFit(contentSize, toFit);
	return aspectFitSize;
}

- (void)setNeedsLayout {
	[super setNeedsLayout];
	[contentView setNeedsLayout];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	DDLogDebug(@"Layout subviews of view %@ to %@", self, NSStringFromCGRect(self.bounds));
	CGRect bounds = self.bounds;
	previewLayer.position = CGPointMake(bounds.size.width * 0.5, bounds.size.height * 0.5);
	CGSize aspectFitSize = [self sizeThatFits:bounds.size];
	if ( !CGSizeEqualToSize(previewLayer.bounds.size, aspectFitSize) ) {
		previewLayer.bounds = CGRectMake(0, 0, aspectFitSize.width, aspectFitSize.height);
		
		// Discovered a nifty trick with CATiledLayer, in that if you change the transform when resizing
		// the view, instead of the bounds, it does not re-draw and flash on the screen. So, if the size
		// has changed, but is an aspect-scaled size change, just change the transform on the view to match
		// the new scale. Otherwise set the bounds to match so that future size changes (i.e. from
		// orientation changes) can just apply the transform instead of changing the view bounds.
		
		CGFloat dw = bounds.size.width / contentView.bounds.size.width;
		CGFloat dh = bounds.size.height / contentView.bounds.size.height;
		if ( ABS(dw - dh) < 0.002 ) {
			contentView.transform = CGAffineTransformMakeScale(dw, dh);
		} else {
			// just set frame so our aspect size matches, then we later adjust via transforms
			contentView.transform = CGAffineTransformIdentity;
			contentView.bounds = previewLayer.bounds;
		}
	} else if ( !CGSizeEqualToSize(contentView.bounds.size, aspectFitSize) ) {
		contentView.transform = CGAffineTransformIdentity;
		contentView.bounds = CGRectMake(0, 0, aspectFitSize.width, aspectFitSize.height);
	}
	contentView.center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
}

#pragma mark Drawing

- (void)setNeedsDisplay {
	[super setNeedsDisplay];
	// pass to content view
	[contentView setNeedsDisplay];
}

- (void)setNeedsDisplayInRect:(CGRect)rect {
	[super setNeedsDisplayInRect:rect];
	
	// pass to content view
	CGRect subviewRect = CGRectIntegral([contentView convertRect:rect fromView:self]);
	[contentView setNeedsDisplayInRect:subviewRect];
}

- (void)updatedContent {
	contentView.transform = CGAffineTransformIdentity;
	contentView.frame = self.bounds;
	previewLayer.frame = self.bounds;
	[[self zoomer] setZoomScale:1 animated:NO];
	[self setNeedsDisplay];
	if ( previewDisabled == NO ) {
		// query for available CGImageRef, to draw immediately
		id key = [delegate previewImageKeyForView:self];

		// without this transaction, we get an implicit fade-out of the existing content, which during
		// view re-cycling causes an unwanted cross-fade effect between the old contents and the new image
		// set later in drawPreviewImage:
		[CATransaction begin]; {
			[CATransaction setDisableActions:YES];
			previewLayer.contents = nil;
			[previewLayer setValue:key forKey:kPreviewKey];
		} [CATransaction commit];
		
		BOOL needsPreview = YES;
		if ( [delegate respondsToSelector:@selector(previewImageForView:atSize:)] ) {
			UIImage *img = [delegate previewImageForView:self atSize:previewSize];
			if ( img != NULL ) {
				needsPreview = NO;
				[self drawPreviewImage:img key:key];
			}
		}
		if ( needsPreview ) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				UIImage *img = [delegate renderPreviewImageForView:self key:key atSize:previewSize];
				dispatch_async(dispatch_get_main_queue(), ^{
					[self drawPreviewImage:img key:key];
				});
			});
		}
	}
}

// look for a super view that has this view as it's zooming view
- (UIScrollView *)zoomer {
	if ( [self.superview isKindOfClass:[UIScrollView class]] ) {
		UIScrollView *zoomer = (UIScrollView *)self.superview;
		UIView *zoomView = [zoomer.delegate viewForZoomingInScrollView:zoomer];
		if ( zoomView == self ) {
			return zoomer;
		}
	}
	return nil;
}

- (void)drawPreviewImage:(UIImage *)image key:(id)key {
	DDLogDebug(@"Drawing preview %@ to layer size %@ (view size %@)",
			  NSStringFromCGSize(image.size),
			  NSStringFromCGSize(previewLayer.bounds.size),
			  NSStringFromCGSize(self.bounds.size));
	// this may not be the main thread...
	const BOOL displayPreviewImage = [[previewLayer valueForKey:kPreviewKey] isEqual:key];
	const CGSize displaySize = [delegate displaySizeForView:self];
	const CGSize scaledSize = BRAspectSizeToFit(image.size, displaySize);
	const CGRect aspectFitBounds = CGRectMake(0, 0, scaledSize.width, scaledSize.height);
	if ( previewLayer != nil && previewLayer.contents == nil && displayPreviewImage ) {
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		previewLayer.contents = (__bridge id)image.CGImage;
		self.frame = aspectFitBounds;
		previewLayer.bounds = aspectFitBounds;
		previewLayer.position = CGPointMake(scaledSize.width * 0.5, scaledSize.height * 0.5);
		if ( previewFadeDuration > 0.0 ) {
			previewLayer.opacity = 0.0;
		}
		[CATransaction commit];
		UIScrollView *zoomer = [self zoomer];
		if ( zoomer != nil ) {
			zoomer.contentSize = scaledSize;
			zoomer.contentOffset = CGPointZero;
		}
		if ( previewFadeDuration > 0.0 ) {
			[CATransaction begin];
			// fade in to smooth out the transition, after fade show tiled layer
			[CATransaction setAnimationDuration:previewFadeDuration];
			previewLayer.opacity = 1.0;
			[CATransaction setCompletionBlock:^(void) {
				// TODO: query for full content...contentView.layer.hidden = NO;
			}];
			[CATransaction commit];
		} else {
			// no fade, just blast everything on immediately
			// TODO: query for full content contentView.layer.hidden = NO;
		}
		if ( [delegate respondsToSelector:@selector(didDisplayPreviewImageForView:)] ) {
			[delegate didDisplayPreviewImageForView:self];
		}
	}
}

@end
