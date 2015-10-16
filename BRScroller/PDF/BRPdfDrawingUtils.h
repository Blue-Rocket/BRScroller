//
//  BRPdfDrawingUtils.h
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
 Get the natural size of a PDF page.
 
 @param page The page.
 
 @return The natural size of the page.
 */
CGSize BRScrollerPdfNaturalSize(CGPDFPageRef page);

/**
 Draw a PDF page to a CGContext, optionally flipping the Y axis if @c flipped is true.
 
 @param page            The PDF page to draw.
 @param rect            The frame to draw the PDF content at.
 @param backgroundColor The background color to apply to the drawing area, or @c NULL for no color.
 @param context         The context to draw to.
 @param flipped         Flip the Y axis if true.
 */
void BRScrollerPdfDrawPage(CGPDFPageRef page, CGRect rect, CGColorRef backgroundColor, CGContextRef context, bool flipped);

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
