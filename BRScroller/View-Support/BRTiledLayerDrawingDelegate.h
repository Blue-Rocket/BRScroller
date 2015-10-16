//
//  BRTiledLayerDrawingDelegate.h
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

/**
 API for a tiled layer drawing delegate.
 */
@protocol BRTiledLayerDrawingDelegate <NSObject>

@required

/**
 Callback when rendering content for a single tile in an overall tiled view.
 This may be called by a background thread. The layer might be sized for just
 a single tile, or it might be the same dimensions as theView; use @c theView
 for calculating all world dimensions, etc. The context's clip bounds will
 determine the frame of the tile within the overall content.
 
 @param theView The view supporting the tiled layer.
 @param layer   The layer being drawn.
 @param context The drawing context.
 */
- (void)tiledLayerView:(UIView *)theView drawingToLayer:(CALayer *)layer context:(CGContextRef)context;

@end
