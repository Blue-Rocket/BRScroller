//
//  BRZoomingImageView.h
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRCenteringScrollView.h"

@class BRImagePreviewLayerView;

NS_ASSUME_NONNULL_BEGIN

/**
 Thin wrapper around @c BRCenteringScrollView to support showing a zoomable image.
 */
@interface BRZoomingImageView : BRCenteringScrollView

/** The image view that serves as the zoomable content. */
@property (nonatomic, strong, readonly) BRImagePreviewLayerView *imageView;

@end

NS_ASSUME_NONNULL_END
