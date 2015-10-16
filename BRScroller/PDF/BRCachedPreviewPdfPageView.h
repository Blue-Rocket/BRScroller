//
//  BRCachedPreviewPdfPageView.h
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

#import "BRImageRenderService.h"
#import "BRTiledPdfPageView.h"

/**
 View that makes use of a bitmap image "preview" to quickly show PDF content while drawing
 the actual PDF using a tiled layer.
 */
@interface BRCachedPreviewPdfPageView : UIView

/** The size of the bitmap preview image to request */
@property (nonatomic, assign) CGSize previewSize;

/** The tiled PDF page view to use. */
@property (nonatomic, strong) BRTiledPdfPageView *pageView;

/** A service to assist with rendering preview images. */
@property (nonatomic, strong) id<BRImageRenderService> previewService;

/** A flag to disable the preview layer. */
@property (nonatomic, assign, getter = isPreviewDisabled) BOOL previewDisabled;

/** A unique key associated with the configured PDF page, to use with caching. */
@property (nonatomic, readonly) NSString *key;

- (void)updateContentWithPage:(CGPDFPageRef)pdfPage atIndex:(NSUInteger)pageIndex withKey:(NSString *)key;

@end
