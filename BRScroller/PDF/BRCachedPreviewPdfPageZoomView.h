//
//  BRCachedPreviewPdfPageZoomView.h
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRCenteringScrollView.h"

#import "BRCachedPreviewPdfPageView.h"

@interface BRCachedPreviewPdfPageZoomView : BRCenteringScrollView

@property (nonatomic, strong) BRCachedPreviewPdfPageView *pdfView;

// call to reset the view with a new page
- (void)setPage:(CGPDFPageRef)page forIndex:(NSUInteger)pageIndex withKey:(NSString *)key;

@end
