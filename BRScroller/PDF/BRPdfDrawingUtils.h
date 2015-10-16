//
//  BRPdfDrawingUtils.h
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRDrawingUtils.h"

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
