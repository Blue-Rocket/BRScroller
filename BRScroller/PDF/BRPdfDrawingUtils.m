//
//  BRPdfDrawingUtils.m
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRPdfDrawingUtils.h"

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

CGSize RCPdfWorldSize(CGSize worldSize, int pageRotation) {
	if ( (abs(pageRotation) / 90) % 2 == 1 ) {
		CGFloat tmp = worldSize.width;
		worldSize.width = worldSize.height;
		worldSize.height = tmp;
	}
	return worldSize;
}

CGSize BRScrollerPdfNaturalSize(CGPDFPageRef page) {
	if ( page == NULL ) {
		return CGSizeZero;
	}
	CGSize pdfSize = CGPDFPageGetBoxRect(page, kCGPDFCropBox).size;
	int pageRotation = CGPDFPageGetRotationAngle(page); // only allowed to be 0, ±90, ±180, ±270
	return RCPdfWorldSize(pdfSize, pageRotation);
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

void BRScrollerPdfDrawPage(CGPDFPageRef page, CGRect rect, CGColorRef backgroundColor,
				   CGContextRef context, bool flipped) {
	CGSize pdfSize = BRScrollerPdfNaturalSize(page);
	CGSize fitSize = BRScrollerAspectSizeToFit(pdfSize, rect.size);
	
	// the following scale and translation values compenstate for CGPDFPageGetDrawingTransform which only scales down, not UP
	
	CGFloat scale = 1.0;
	if ( pdfSize.width < rect.size.width) {
		scale = rect.size.width / pdfSize.width;
	}
	if ( pdfSize.height < rect.size.height ) {
		scale = rect.size.height / pdfSize.height;
	}
	
	CGFloat tx = rect.origin.x + (0.0 - (pdfSize.width < rect.size.width ? (((rect.size.width - pdfSize.width) / 2.0) * scale) : 0.0));
	CGFloat ty;
	if ( flipped ) {
		ty = rect.origin.y + (rect.size.height + (pdfSize.height < rect.size.height ? (((rect.size.height - pdfSize.height) / 2.0) * scale) : 0.0));
	} else {
		ty = rect.origin.y - (                   (pdfSize.height < rect.size.height ? (((rect.size.height - pdfSize.height) / 2.0) * scale) : 0.0));
	}
	
	// CGPDFPageGetDrawingTransform will also scale the result,
	// but only down so we only apply scale > 1
	if ( scale < 1.0 ) {
		scale = 1.0;
	}
	
	CGContextSaveGState(context);
	{
		// fill in PDF background with our own background view color, otherwise
		// layer seems to draw black background followed by PDF content
		CGRect pageRect = CGRectIntegral(CGRectMake(rect.origin.x + (rect.size.width - fitSize.width) / 2.0,
													rect.origin.y + (rect.size.height - fitSize.height) / 2.0,
													fitSize.width,
													fitSize.height));
		if ( backgroundColor != NULL ) {
			CGContextSetFillColorWithColor(context, backgroundColor);
			CGContextFillRect(context, pageRect);
		}
		
		// PDFs can draw outside their defined page box, so clip to the box here
		// MSM: commenting out, because clipping slightly edges of PDFs drawn in places like icons, where
		//      we have slight fractional differences in pageRect from rect. Need to investigate a bit more.
		//CGContextClipToRect(context, pageRect);
		
		CGContextTranslateCTM(context, tx, ty);
		CGContextScaleCTM(context, scale, (flipped ? -scale : scale));
		CGAffineTransform pdfXform = CGPDFPageGetDrawingTransform(page, kCGPDFCropBox, CGRectMake(0, 0, rect.size.width, rect.size.height), 0, false);
		CGContextConcatCTM(context, pdfXform);
		
		CGContextDrawPDFPage(context, page);
	} CGContextRestoreGState(context);
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

