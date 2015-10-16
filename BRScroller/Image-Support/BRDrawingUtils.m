//
//  BRDrawingUtils.m
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRDrawingUtils.h"

CGSize BRScrollerAspectSizeToFit(CGSize aSize, CGSize maxSize) {
	CGFloat scale = 1.0;
	if ( aSize.width > 0.0 && aSize.height > 0.0 ) {
		CGFloat dw = maxSize.width / aSize.width;
		CGFloat dh = maxSize.height / aSize.height;
		scale = dw < dh ? dw : dh;
	}
	return CGSizeMake(MIN(floorf(maxSize.width), ceilf(aSize.width * scale)),
					  MIN(floorf(maxSize.height), ceilf(aSize.height * scale)));
}

// thanks, ye ol' bithacks: http://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2Float
unsigned int BRScrollerRoundedToPowerOf2(const float v) {
	unsigned int r;
	if ( v > 1.0 ) {
		float f = (ceilf(v) - 1);
		r = 1U << ((*(unsigned int*)(&f) >> 23) - 126);
	} else {
		r = 1;
	}
	return r;
}

static const int kBitsPerComponent = 8;
static const int kNumComponents = 4;

static CGContextRef CreateBitmapContext(int pixelsWide, int pixelsHigh, CGBitmapInfo bitmapInfo) {
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, pixelsWide, pixelsHigh, kBitsPerComponent,
												 kNumComponents * pixelsWide, colorSpace, bitmapInfo);
	CGColorSpaceRelease(colorSpace);
	if ( context == NULL ) {
		fprintf(stderr, "Context not created!");
	}
	return context;
}

CGContextRef BRScrollerCreateBitmapContext(CGSize bitmapSize) {
	return CreateBitmapContext((int)bitmapSize.width, (int)bitmapSize.height,
							   (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host));
}

CGContextRef BRScrollerCreateBitmapContextNoAlpha(CGSize bitmapSize) {
	return CreateBitmapContext((int)bitmapSize.width, (int)bitmapSize.height,
							   kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host);
}
