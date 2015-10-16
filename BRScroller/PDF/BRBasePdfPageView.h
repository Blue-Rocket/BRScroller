//
//  BRBasePdfPageView.h
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A base view class with support for rendering a single PDF page.
 */
@interface BRBasePdfPageView : UIView

/** The PDF page to render. */
@property (nonatomic, nullable) CGPDFPageRef page;

/** The zero-based page index this page represents. */
@property (nonatomic, assign) NSUInteger pageIndex;

- (void)drawInRect:(CGRect)rect context:(CGContextRef)context;
- (void)pdfDocumentDidChange;
- (void)pdfPageDidChange;
- (CGSize)naturalSize;

@end

NS_ASSUME_NONNULL_END
