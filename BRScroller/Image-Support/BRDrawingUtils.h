//
//  BRDrawingUtils.h
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/**
 Calculate the size that scales @c size to maximally fit within @c maxSize while preserving its aspect ratio.
 
 
 @param aSize   The size to scale.
 @param maxSize The maximum size to scale to.
 
 @return The calcualted size.
 */
CGSize BRScrollerAspectSizeToFit(CGSize aSize, CGSize maxSize);

/**
 Round a floating point number to the nearest power of two.
 
 @param v The number to round.
 
 @return The rounded value.
 */
unsigned int BRScrollerRoundedToPowerOf2(const float v);

/**
 Create a new bitmap image context without alpha support.
 
 @param bitmapSize The size of the context to create.
 
 @return The context.
 */
CGContextRef BRScrollerCreateBitmapContext(CGSize bitmapSize);

/**
 Create a new bitmap image context with alpha support.
 
 @param bitmapSize The size of the context to create.
 
 @return The context.
 */
CGContextRef BRScrollerCreateBitmapContextNoAlpha(CGSize bitmapSize);
