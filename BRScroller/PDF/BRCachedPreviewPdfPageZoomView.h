//
//  BRCachedPreviewPdfPageZoomView.h
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRCenteringScrollView.h"

#import "BRCachedPreviewPdfPageView.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A zoomable scroll view for displaying a single page from a PDF document.
 */
@interface BRCachedPreviewPdfPageZoomView : BRCenteringScrollView

/** The zooming content view to display the PDF page. Defaults to a non-nil value. */
@property (nonatomic, strong) BRCachedPreviewPdfPageView *pdfView;

/**
 Display a page from a PDF document. This will invoke @c updateContentWithPage:atIndex:withKey:
 on the configured @c pdfView.
 
 @param page      The page to display.
 @param pageIndex The index of the page being shown.
 @param key       A unique key for this page.
 */
- (void)setPage:(CGPDFPageRef)page forIndex:(NSUInteger)pageIndex withKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
