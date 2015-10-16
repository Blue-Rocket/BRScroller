//
//  BRTiledPdfPageView.h
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRBasePdfPageView.h"

#import "BRTiledLayerDrawingDelegate.h"

/**
 View for drawing a single PDF page using a tiled layer to support zooming.
 */
@interface BRTiledPdfPageView : BRBasePdfPageView

@property (nonatomic, assign) size_t tileLevelsOfDetail;
@property (nonatomic, assign) size_t tileLevelsOfDetailBias;
@property (nonatomic, assign) CGSize tileSize;

/**
 If YES (the default is NO) then when setDisplayInRect: is called, a bitmap "snapshot"
 is created from the current layer and inserted as a sublayer before re-drawing
 the tiled layer. The goal of this is to prevent "flashing" on the screen while
 the tiled layer is re-drawn, as CATiledLayer will clear the tile before re-drawing.
 Note this only works when this view has a UIScrollView ancestor view. The snapshots
 are automatically discarded after a short time, under the assumption the CATiledLayer
 will have completed its redrawing of the tiles beneath the snapshots.
 */
@property (nonatomic, assign, getter = isSnapshotOnRefresh) BOOL snapshotOnRefresh;

/**
 If YES (the default is NO) then when snapshots are created (by snapshotOnRefresh
 being set to YES) the snapshots are cached in memory indefinitely. Normally the
 snapshots are discarded after a short time. This can be used in situations where
 drawing performance is critical at the expense of additional memory.
 */
@property (nonatomic, assign, getter = isSnapshotCacheEnabled) BOOL snapshotCacheEnabled;

/**
 If YES during a callback on drawDelegate, a cached snapshot is being generated,
 otherwise a non-cached tile is being generated.
 */
@property (nonatomic, readonly, getter = isRenderingCachedTile) BOOL renderingCachedTile;

/**
 NOTE: as this is not retained, it is calling code's responsibility to
 set this to nil if the delegate is getting released! This view uses
 background threads to draw, so might not be released even if the superview
 itself has been released, and the delegate can be called still.
 */
@property (nonatomic, weak) id<BRTiledLayerDrawingDelegate> drawDelegate;

/**
 Remove any snapshot layer(s) present.
 */
- (void) removeSnapshotLayers;

@end
