//
//  BRImagePreviewLayerView.m
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRImagePreviewLayerView.h"

#import "BRAsyncImageView.h"

@implementation BRImagePreviewLayerView

- (id)initWithFrame:(CGRect)frame {
	if ( (self = [super initWithFrame:frame]) ) {
		[self initializeBRImagePreviewLayerViewDefaults];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ( (self = [super initWithCoder:aDecoder]) ) {
		[self initializeBRImagePreviewLayerViewDefaults];
	}
	return self;
}

- (void)initializeBRImagePreviewLayerViewDefaults {
	BRAsyncImageView *imageView = [[BRAsyncImageView alloc] initWithFrame:self.bounds];
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	if ( [imageView respondsToSelector:@selector(setTranslatesAutoresizingMaskIntoConstraints:)] ) {
#pragma deploymate push "ignored-api-availability"
		imageView.translatesAutoresizingMaskIntoConstraints = NO;
#pragma deploymate pop
	}
	[super setContentView:imageView];
}

#pragma mark - Accessors

- (NSURL *)imageURL {
	return ((BRAsyncImageView *)self.contentView).imageURL;
}

- (void)setImageURL:(NSURL *)imageURL {
	BRAsyncImageView *imageView = (BRAsyncImageView *)self.contentView;
	imageView.imageURL = imageURL;
	[self updatedContent];
}

- (NSData *)imageData {
	return ((BRAsyncImageView *)self.contentView).imageData;
}

- (void)setImageData:(NSData *)imageData {
	BRAsyncImageView *imageView = (BRAsyncImageView *)self.contentView;
	imageView.imageData = imageData;
	[self updatedContent];
}

- (void)setContentView:(UIView *)contentView {
	// allow users to specify a custom subclass if needed, as long as it provides an imageURL property
	NSAssert(([contentView respondsToSelector:@selector(setImageURL:)]
			  && [contentView respondsToSelector:@selector(imageURL)])
			 || ([contentView respondsToSelector:@selector(setImageData:)]
				 && [contentView respondsToSelector:@selector(imageData)]),
			 @"contentView must provide either a imageURL or imageData readwrite property");
	[super setContentView:contentView];
}

- (BRAsyncImageView *)imageContentView {
	return (BRAsyncImageView *)self.contentView;
}

- (void)setImageContentView:(BRAsyncImageView *)imageView {
	[super setContentView:imageView];
}

@end
