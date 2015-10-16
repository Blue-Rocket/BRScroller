//
//  BRZoomingImageView.h
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRCenteringScrollView.h"

@class BRImagePreviewLayerView;

@interface BRZoomingImageView : BRCenteringScrollView

@property (nonatomic, strong, readonly) BRImagePreviewLayerView *imageView;

@end
