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
 Thin wrapper of BRPreviewLayerView to handle a common case of using a UIImage for the
 content. A default BRAsyncImageView is used for the contentView, but you may provide your
 view by setting the contentView property, as long as that view supports a NSURL
 `imageURL` property or a NSData `imageData` property.
 */
@interface BRImagePreviewLayerView : BRPreviewLayerView

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) NSData *imageData;

/** Alias for getting / setting the contentView property. */
@property (nonatomic, strong) BRAsyncImageView *imageContentView;

@end
