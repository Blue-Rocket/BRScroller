//
//  BRTiledPdfPageView.m
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRTiledPdfPageView.h"

#import <QuartzCore/QuartzCore.h>
#import "BRPdfDrawingUtils.h"
#import "BRScrollerLogging.h"

@interface RCTiledPdfPageViewSnapshotDelegate : NSObject {
	BRTiledPdfPageView *pageView;
}
- (id)initWithPageView:(BRTiledPdfPageView *)view;
@end

#pragma mark -

@interface RCTiledPdfPageViewFastFadeTiledLayer : CATiledLayer
@end

#pragma mark -

static NSString * const kCachedSnapshotKeys = @"RCCachedSnapshotKeys";
static NSString * const kCachedSnapshotCacheKey = @"RCCachedSnapshotCacheKey";
static NSString * const kCachedSnapshotImage = @"RCCachedSnapshotImage";
static NSString * const kCachedSnapshotScale = @"RCCachedSnapshotScale";
static NSString * const kCachedSnapshotTileRect = @"RCCachedSnapshotTileRect";

// Defining the DEBUG_TILES property turns on border properties on snapshot tiles
// and is useful for visually debugging, it will show where the bitmap layer ends up
// getting positioned. If everything goes as planned, you won't be able to see where
// the bitmap layers are as they will blend perfectly with the rest of the layer content.
#undef DEBUG_TILES

@implementation BRTiledPdfPageView {
	size_t tileLevelsOfDetail;
	size_t tileLevelsOfDetailBias;
	CGSize tileSize;
	CGFloat contentsScale;
	id<BRTiledLayerDrawingDelegate> __weak drawDelegate;
	BOOL snapshotOnRefresh;
	BOOL snapshotCacheEnabled;
	BOOL renderingCachedTile;
}

@synthesize drawDelegate, tileLevelsOfDetail, tileLevelsOfDetailBias, tileSize;
@synthesize snapshotOnRefresh, snapshotCacheEnabled, renderingCachedTile;

+ (Class) layerClass {
	return [RCTiledPdfPageViewFastFadeTiledLayer class];
}

- (id) initWithFrame:(CGRect)frame {
	if ( (self = [super initWithFrame:frame]) ) {
		tileLevelsOfDetail = 1;
		tileLevelsOfDetailBias = 3;
		tileSize = CGSizeMake(1024.0, 1024.0);
		contentsScale = 1.0;
		CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
		tiledLayer.tileSize = tileSize;
		tiledLayer.levelsOfDetail = tileLevelsOfDetail;
		tiledLayer.levelsOfDetailBias = tileLevelsOfDetailBias;
		tiledLayer.edgeAntialiasingMask = 0;
		tiledLayer.actions = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"sublayers"];
		snapshotOnRefresh = NO;
		snapshotCacheEnabled = NO;
		self.backgroundColor = [UIColor whiteColor];
	}
	return self;
}

- (void) dealloc {
	drawDelegate = nil; // not retained
}

- (void) pdfPageDidChange {
	[self setNeedsDisplay];
}

- (void)setDrawDelegate:(id<BRTiledLayerDrawingDelegate>)delegate {
	if ( delegate != drawDelegate ) {
		@synchronized(self) {
			drawDelegate = delegate; // not retained
		}
	}
}

static NSString * const kSnapshotDrawDelegate = @"RCSnapshotDrawDelegate";

- (RCTiledPdfPageViewSnapshotDelegate *)snapshotDrawDelegate {
	RCTiledPdfPageViewSnapshotDelegate *delegate = [self.layer valueForKey:kSnapshotDrawDelegate];
	if ( delegate == nil ) {
		delegate = [[RCTiledPdfPageViewSnapshotDelegate alloc] initWithPageView:self];
		[self.layer setValue:delegate forKey:kSnapshotDrawDelegate];
	}
	return delegate;
}

#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
	// need empty impl for UIView to call drawLayer:inContext:
}

- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)context {
	DDLogDebug(@"Drawing tile rect %@", NSStringFromCGRect(CGContextGetClipBoundingBox(context)));
	[self drawInRect:theLayer.bounds context:context];
	
	// get a thread-safe reference to the delegate
	id<BRTiledLayerDrawingDelegate> delegate = nil;
	@synchronized(self) {
		delegate = drawDelegate;
	}
	[delegate tiledLayerView:self drawingToLayer:theLayer context:context];
}

- (void)didMoveToWindow {
	DDLogDebug(@"Did move to window, contentsScale = %f", self.layer.contentsScale);
	// Retina display work-around: so 1024x1024 tiles are drawn instead of 512x512 tiles
	contentsScale = self.layer.contentsScale;
	self.layer.contentsScale = 1.0;
}

- (void)handleRemoveSnapshotLayer:(CALayer *)layer cache:(NSMutableDictionary *)cache {
	DDLogDebug(@"Removing snapshot image sublayer %@", layer);
	NSString *cacheKey = [layer valueForKey:kCachedSnapshotCacheKey];
	if ( cacheKey != nil ) {
		[cache removeObjectForKey:cacheKey];
	}
	[layer removeFromSuperlayer];
}

- (void)removeSnapshotLayer:(CALayer *)layer {
	if ( layer != nil ) {
		[CATransaction begin]; {
			[CATransaction setDisableActions:YES];
			[self handleRemoveSnapshotLayer:layer cache:[self snapshotCacheSet]];
		} [CATransaction commit];
	}
}

- (void)removeSnapshotLayers {
	NSArray *sublayers = self.layer.sublayers;
	if ( [sublayers count] > 0 ) {
		[CATransaction begin]; {
			[CATransaction setDisableActions:YES];
			DDLogDebug(@"Removing snapshot image sublayers %@", sublayers);
			NSMutableDictionary *cache = [self snapshotCacheSet];
			for ( CALayer *layer in [sublayers copy] ) {
				[self handleRemoveSnapshotLayer:layer cache:cache];
			}
		} [CATransaction commit];
	}
}

- (UIScrollView *)findVisibilityView {
	UIView *v = self;
	Class clazz = [UIScrollView class];
	while ( v.superview != nil ) {
		v = v.superview;
		if ( [v isKindOfClass:clazz] ) {
			return (UIScrollView *)v;
		}
	}
	return nil;
}

- (void)setNeedsDisplay {
	[self removeSnapshotLayers];
	[super setNeedsDisplay];
}

- (void)populateVisibleSnapshot {
	UIScrollView *visibilityView = [self findVisibilityView];
	if ( visibilityView == nil ) {
		return;
	}
	
	const CGRect visibleFrame = CGRectIntegral(CGRectIntersection([visibilityView convertRect:visibilityView.bounds toView:self], self.bounds));
	
	if ( !(visibleFrame.size.width > 0.0f && visibleFrame.size.height > 0.0f) ) {
		return;
	}
	
	[BRTiledPdfPageView cancelPreviousPerformRequestsWithTarget:self];
	
	CALayer *imgLayer;
	CGImageRef img;
	CGContextRef bitmapContext;
	[CATransaction begin]; {
		[CATransaction setDisableActions:YES];
		[self removeSnapshotLayers];
		
		// we might have a scale transform applied to us, which impacts the size of our bitmap because
		// the CATiledLayer will have scaled to accommodate the transform! We *assume* here that *only*
		// a scale transform is applied! In addition we scale our bitmap to the nearest power of 2, to
		// render at the same detail level as the CATiledLayer. We do this so we get a pixel-perfect copy
		// on screen, as far as the user is concerned.
		
		const CGAffineTransform viewTransform = self.transform;
		const CGSize scales = CGSizeMake(BRScrollerRoundedToPowerOf2(visibilityView.zoomScale * viewTransform.a) * contentsScale,
										 BRScrollerRoundedToPowerOf2(visibilityView.zoomScale * viewTransform.d)  * contentsScale);
		const CGSize bitmapSize = CGSizeMake(ceilf(visibleFrame.size.width * scales.width),
											 ceilf(visibleFrame.size.height * scales.height));
		
		bitmapContext = BRScrollerCreateBitmapContextNoAlpha(bitmapSize);
		CGContextConcatCTM(bitmapContext, CGAffineTransformMakeTranslation(-visibleFrame.origin.x * scales.width,
																		   visibleFrame.origin.y * scales.height + visibleFrame.size.height * scales.height));
		CGContextConcatCTM(bitmapContext, CGAffineTransformMakeScale(scales.width, -scales.height));
		[self.layer renderInContext:bitmapContext];
		img = CGBitmapContextCreateImage(bitmapContext);
		
		const CGAffineTransform bitmapTransform = CGAffineTransformInvert(CGAffineTransformMakeScale(scales.width, scales.height));
		
		imgLayer = [CALayer layer];
		imgLayer.bounds = CGRectMake(0, 0, bitmapSize.width, bitmapSize.height);
		imgLayer.anchorPoint = CGPointMake(0, 0);
		imgLayer.position = visibleFrame.origin;
		imgLayer.contents = (__bridge id)img;
		imgLayer.transform = CATransform3DMakeAffineTransform(bitmapTransform);
		imgLayer.opacity = 0.98; // this forces the CATiledLayer to still render under this bitmap!
		
#ifdef DEBUG_TILES
		imgLayer.borderWidth = 1.0;
		imgLayer.borderColor = [UIColor greenColor].CGColor;
#endif
		
		DDLogDebug(@"Adding snapshot image sublayer %@ %@", imgLayer, NSStringFromCGSize(bitmapSize));
		[self.layer addSublayer:imgLayer];
	} [CATransaction commit];
	CGImageRelease(img);
	CGContextRelease(bitmapContext);
	
	[self performSelector:@selector(removeSnapshotLayer:) withObject:imgLayer afterDelay:2.0];
}

- (NSMutableDictionary *)snapshotCacheSet {
	NSMutableDictionary *snapshotCacheSet = [self.layer valueForKey:kCachedSnapshotKeys];
	if ( snapshotCacheSet == nil ) {
		snapshotCacheSet = [self.layer valueForKey:kCachedSnapshotKeys];
		if ( snapshotCacheSet == nil ) {
			snapshotCacheSet = [NSMutableDictionary dictionaryWithCapacity:32];
			[self.layer setValue:snapshotCacheSet forKey:kCachedSnapshotKeys];
		}
	}
	return snapshotCacheSet;
}

- (void) populateCachedSnapshotsInRect:(CGRect)rect {
	// create snapshots based on visible tiles
	UIScrollView *visibilityView = [self findVisibilityView];
	if ( visibilityView == nil ) {
		return;
	}
	
	// the visible rect in terms of the original content size
	const CGRect visibleContentFrame = CGRectIntegral(CGRectIntersection([visibilityView convertRect:visibilityView.bounds toView:self], self.bounds));
	
	if ( !(visibleContentFrame.size.width > 0.0f && visibleContentFrame.size.height > 0.0f) ) {
		return;
	}
	
	NSMutableDictionary *snapshotCacheSet = [self snapshotCacheSet];
	
	const CGRect viewBounds = self.bounds;
	
	const CGAffineTransform viewTransform = self.transform;
	const CGSize scales = CGSizeMake(BRScrollerRoundedToPowerOf2(visibilityView.zoomScale * viewTransform.a) * contentsScale,
									 BRScrollerRoundedToPowerOf2(visibilityView.zoomScale * viewTransform.d)  * contentsScale);
	const CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scales.width, scales.height);
	const CGAffineTransform scaleFlipTransform = CGAffineTransformMakeScale(scales.width, -scales.height);
	const CGAffineTransform invertScaleTransform = CGAffineTransformInvert(scaleTransform);
	
	// tileContentSize is the effective size of our tiles at the current zoom level on the original content... e.g.
	// how many pixels at zoom level 1 does the tile cover? For example at zoom level 2, we have 512px tiles.
	const CGSize tileContentSize = CGSizeMake(tileSize.width / scales.width, tileSize.height / scales.height);
	
	const int firstCol = floorf(CGRectGetMinX(viewBounds) / tileContentSize.width);
	const int lastCol = floorf((CGRectGetMaxX(viewBounds)-1) / tileContentSize.width);
	const int firstRow = floorf(CGRectGetMinY(viewBounds) / tileContentSize.height);
	const int lastRow = floorf((CGRectGetMaxY(viewBounds)-1) / tileContentSize.height);
	
	renderingCachedTile = YES;
	
	[CATransaction begin]; {
		[CATransaction setDisableActions:YES];
		
		// we must hide all existing sublayers, so they are not rendered into our cached tile images
		[self.layer.sublayers makeObjectsPerformSelector:@selector(setHidden:) withObject:[NSNumber numberWithBool:YES]];
		
		// keep track of which tiles we actually need to show
		NSMutableArray *layersToShow = [NSMutableArray arrayWithCapacity:4];
		
		for (int row = firstRow; row <= lastRow; row++) {
			for (int col = firstCol; col <= lastCol; col++) {
				const CGRect tileRect = CGRectIntersection(viewBounds, CGRectMake(col * tileContentSize.width, row * tileContentSize.height,
																				  tileContentSize.width, tileContentSize.height));
				NSString *cacheKey = NSStringFromCGRect(tileRect);
				DDLogDebug(@"Inspecting tile %@", cacheKey);
				CALayer *imgLayer = [snapshotCacheSet objectForKey:cacheKey];
				if ( CGRectIntersectsRect(tileRect, visibleContentFrame) ) {
					CGSize bitmapSize = CGSizeApplyAffineTransform(tileRect.size, scaleTransform);
					CGImageRef img = CGImageRetain((CGImageRef)[imgLayer valueForKey:kCachedSnapshotImage]);
					if ( imgLayer == nil ) {
						DDLogDebug(@"Caching snapshot image sublayer %@"	, cacheKey);
						CGContextRef bitmapContext = BRScrollerCreateBitmapContextNoAlpha(bitmapSize);
						CGContextConcatCTM(bitmapContext, CGAffineTransformMakeTranslation(-tileRect.origin.x * scales.width,
																						   tileRect.origin.y * scales.height + tileRect.size.height * scales.height));
						CGContextConcatCTM(bitmapContext, scaleFlipTransform);
						[self.layer renderInContext:bitmapContext];
						img = CGBitmapContextCreateImage(bitmapContext);
						CGContextRelease(bitmapContext);
						
						imgLayer = [CALayer layer];
						imgLayer.bounds = CGRectMake(0, 0, bitmapSize.width, bitmapSize.height);
						imgLayer.anchorPoint = CGPointMake(0, 0);
						imgLayer.position = tileRect.origin;
						imgLayer.transform = CATransform3DMakeAffineTransform(invertScaleTransform);
						imgLayer.opacity = 1.0f; // we don't want CATiledLayer to still render under this bitmap
						imgLayer.delegate = [self snapshotDrawDelegate];
						imgLayer.hidden = YES;
						imgLayer.actions = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"contents"];
						
						
						// save our cached bitmap image onto the layer itself
						[imgLayer setValue:(__bridge id)img forKey:kCachedSnapshotImage];
						[imgLayer setValue:[NSValue valueWithCGRect:tileRect] forKey:kCachedSnapshotTileRect];
						[imgLayer setValue:[NSValue valueWithCGSize:scales] forKey:kCachedSnapshotScale];
						[imgLayer setValue:cacheKey forKey:kCachedSnapshotCacheKey];
						
#ifdef DEBUG_TILES
						imgLayer.borderWidth = 1.0;
						imgLayer.borderColor = [UIColor redColor].CGColor;
#endif
						
						imgLayer.contents = (__bridge id)img;
						[self.layer addSublayer:imgLayer];
						
						[snapshotCacheSet setObject:imgLayer forKey:cacheKey];
					}
					
					[layersToShow addObject:imgLayer];
					CGImageRelease(img);
				} else if ( CGRectIntersectsRect(tileRect, rect) ) {
					// always show existing tiles if available, they might get refreshed below
					if ( imgLayer != nil ) {
						[layersToShow addObject:imgLayer];
					} else {
						// no snapshot tile, so let layer below render
						[self.layer setNeedsDisplayInRect:tileRect];
					}
				}
			}
		}
		
		for ( CALayer *imgLayer in layersToShow ) {
			imgLayer.hidden = NO;
			[imgLayer setNeedsDisplayInRect:[imgLayer convertRect:rect fromLayer:self.layer]];
		}
	} [CATransaction commit];
	
	renderingCachedTile = NO;
}

- (void) setNeedsDisplayInRect:(CGRect)rect {
	if ( snapshotOnRefresh && self.hidden == NO && self.alpha > 0.0f ) {
		
		// Here we render a bitmap image snapshot of the visible PDF content,
		// and throw that onto screen via a sublayer of the PDF itself. This
		// works around the problem of the CATiledLayer taking time to render
		// and first clearning the layer content and then fading in the new
		// content. Since we have this snapshot layer added, we don't see the
		// PDF layer disappear and then fade back in.
		//
		// We have to consider also what happens when the user zooms later on.
		// We don't want to show the bitmap snapshot during or after a zoom,
		// because the text and images will end up blurry. So we have to hide
		// the snapshot when the user zoomes. However,  a CATiledLayer will not
		// render its contents if it is not visible, so we have to trick the
		// layer into rendering immediately by setting the opacity of the
		// bitmap snapshot layer to 0.98. This way the CATiledLayer will really
		// render under the snapshot layer, and when the user zooms we can
		// simply discard the snapshot layer and let the CATiledLayer zoom
		// and do its magic.
		
		if ( snapshotCacheEnabled == NO ) {
			[self populateVisibleSnapshot];
			[super setNeedsDisplayInRect:rect];
		} else {
			[self populateCachedSnapshotsInRect:rect];
		}
	} else {
		[super setNeedsDisplayInRect:rect];
	}
}

@end

#pragma mark -

@implementation RCTiledPdfPageViewFastFadeTiledLayer

+ (CFTimeInterval)fadeDuration {
	return 0;
}

@end

#pragma mark -

@implementation RCTiledPdfPageViewSnapshotDelegate

- (id)initWithPageView:(BRTiledPdfPageView *)view {
	if ( (self = [super init]) ) {
		pageView = view; // not retained
	}
	return self;
}

- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)context {
	const CGRect tileRect = [[theLayer valueForKey:kCachedSnapshotTileRect] CGRectValue];
	const CGSize scales = [[theLayer valueForKey:kCachedSnapshotScale] CGSizeValue];
	const CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scales.width, scales.height);
	const CGImageRef img = (__bridge CGImageRef)[theLayer valueForKey:kCachedSnapshotImage];
	
	DDLogDebug(@"Drawing cached tile rect %@ scale %@", NSStringFromCGRect(tileRect), NSStringFromCGSize(scales));
	
	CGContextSaveGState(context); {
		// draw our cached bitmap image onto the layer itself
		CGContextTranslateCTM(context, 0, theLayer.bounds.size.height);
		CGContextScaleCTM(context, 1.0f, -1.0f);
		CGContextSetBlendMode(context, kCGBlendModeNormal);
		CGContextDrawImage(context, theLayer.bounds, img);
	} CGContextRestoreGState(context);
	
	CGContextSaveGState(context); {
		CGContextConcatCTM(context, scaleTransform);
		CGContextConcatCTM(context, CGAffineTransformMakeTranslation(-tileRect.origin.x, -tileRect.origin.y));
		CGContextClipToRect(context, tileRect);
		[pageView.drawDelegate tiledLayerView:pageView drawingToLayer:theLayer context:context];
	} CGContextRestoreGState(context);
}

@end
