//
//  DemoPdfViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. All rights reserved.
//

#import "PdfViewController.h"

#import <BRScroller/BRScroller.h>

@interface PdfViewController () <BRScrollerDelegate>

@end

@implementation PdfViewController {
	BRDefaultImageRenderService *renderService;
	CGPDFDocumentRef pdf;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ( (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) ) {
		renderService = [[BRDefaultImageRenderService alloc] init];
	}
	return self;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ( self.scrollView.loaded == NO ) {
		[self openPdf];
		[self.scrollView reloadData];
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[self closePdf];
}

- (NSString *)pdfPath {
	return [[NSBundle mainBundle] pathForResource:@"SVN Book.pdf" ofType:nil];
}

- (void)openPdf {
	if ( pdf != NULL && CGPDFDocumentIsUnlocked(pdf) ) {
		return;
	}
	if ( pdf == NULL ) {
		if ( [self pdfPath] != nil ) {
			CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)[self pdfPath], kCFURLPOSIXPathStyle, 0);
			if ( url != NULL ) {
				pdf = CGPDFDocumentCreateWithURL(url);
				CFRelease(url);
			}
		} else {
			// neither path nor dataProvider available
			return;
		}
	}
}

- (void)closePdf {
	CGPDFDocumentRelease(pdf);
	pdf = NULL;
}

#pragma mark - BRScrollerDelegate

- (CGFloat)uniformPageWidthForScroller:(BRScrollerView *)scroller {
	return scroller.bounds.size.width;
}

- (NSUInteger)numberOfPagesInScroller:(BRScrollerView *)scroller {
	return CGPDFDocumentGetNumberOfPages(pdf);
}

- (UIView *)createReusablePageViewForScroller:(BRScrollerView *)scroller {
	BRCachedPreviewPdfPageZoomView *zoomer = [[BRCachedPreviewPdfPageZoomView alloc] initWithFrame:self.view.bounds];
	zoomer.pdfView.previewService = renderService;
	zoomer.scrollDelegate = self;
	zoomer.doubleTapToZoom = YES;
	return zoomer;
}

- (void)scroller:(BRScrollerView *)scroller
 willDisplayPage:(NSUInteger)index
			view:(UIView *)reusablePageView {
	BRCachedPreviewPdfPageZoomView *zoomer = (BRCachedPreviewPdfPageZoomView *)reusablePageView;
	CGPDFPageRef page = CGPDFDocumentGetPage(pdf, (index + 1));
	[zoomer setPage:page forIndex:index withKey:@"SVN-Book.jpg"];
}

@end
