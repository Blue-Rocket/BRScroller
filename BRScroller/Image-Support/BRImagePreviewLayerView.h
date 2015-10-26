//
//  BRImagePreviewLayerView.h
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRPreviewLayerView.h"

@class BRAsyncImageView;

/**
 Thin wrapper of @c BRPreviewLayerView to handle a common case of using a @c UIImage for the
 content. A default @c BRAsyncImageView is used for the contentView, but you may provide your
 view by setting the @c contentView property, as long as that view supports either a NSURL 
 property named @c imageURL or a @c NSData property named @c imageData.
 */
@interface BRImagePreviewLayerView : BRPreviewLayerView

/** The URL of the image to display. */
@property (nonatomic, strong, nullable) NSURL *imageURL;

/** Raw image data to display, which takes precedence over the @c imageURL property. */
@property (nonatomic, strong, nullable) NSData *imageData;

/** Alias for getting / setting the @c contentView property. */
@property (nonatomic, strong, nullable) BRAsyncImageView *imageContentView;

@end
