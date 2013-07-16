//
//  BRZoomingImageView.m
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRZoomingImageView.h"

#import "BRImagePreviewLayerView.h"

@implementation BRZoomingImageView {
	BRImagePreviewLayerView *imageView;
}

@synthesize imageView;

- (id)initWithFrame:(CGRect)frame {
    if ( (self = [super initWithFrame:frame]) ) {
        [self initializeBRZoomingImageViewDefaults];
    }
    return self;
}

- (void)initializeBRZoomingImageViewDefaults {
	imageView = [[BRImagePreviewLayerView alloc] initWithFrame:self.bounds];
	[self addSubview:imageView];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return imageView;
}

@end
