//
//  ViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "AsyncPhotoViewController.h"

#import <BRScroller/BRScroller.h>
#import <BRScroller/BRScrollerImageSupport.h>

static const int kNumImages = 10;

@interface AsyncPhotoViewController () <BRScrollerDelegate, BRPreviewLayerViewDelegate, BRAsyncImageViewDelegate>
@end

@implementation AsyncPhotoViewController {
	BRScrollerView *scrollView;
	NSArray *imagePaths; // NSURL paths of images to display
	UIBarButtonItem *prevButton;
	UIBarButtonItem *nextButton;
}

@synthesize scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if ( (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) ) {
		NSMutableArray *paths = [NSMutableArray array];
		for ( int i = 1; i <= kNumImages; i++ ) {
			[paths addObject:[[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"%d.jpeg", i] withExtension:nil]];
		}
		imagePaths = [paths copy];
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	scrollView.scrollerDelegate = self;
	scrollView.pagingEnabled = YES;
	prevButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"prev.label", nil) style:UIBarButtonItemStylePlain target:self action:@selector(goPrevious:)];
	nextButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"next.label", nil) style:UIBarButtonItemStylePlain target:self action:@selector(goNext:)];
	NSDictionary *textAttr = @{ UITextAttributeFont : [UIFont boldSystemFontOfSize:27] };
	[prevButton setTitleTextAttributes:textAttr forState:UIControlStateNormal];
	[nextButton setTitleTextAttributes:textAttr forState:UIControlStateNormal];
	self.navigationItem.leftBarButtonItems = @[prevButton, nextButton];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ( scrollView.loaded == NO ) {
		[scrollView reloadData];
	}
}

- (IBAction)goPrevious:(id)sender {
	[scrollView gotoPreviousPage];
}

- (IBAction)goNext:(id)sender {
	[scrollView gotoNextPage];
}

#pragma mark - BRPreviewLayerViewDelegate

// NOTE: we are generating the preview images on demand, from the full-sized images. This
// is extremely slow. In a real app ideally we would provide pre-rendered preview images here.

- (NSString *)cachedImagePathForImageURL:(NSURL *)imageURL atSize:(CGSize)size {
	NSString *fileName = [[imageURL path] lastPathComponent];
	NSArray *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
	return [NSString stringWithFormat:@"%@/%@-%dx%d.png", cacheDir, fileName, (int)size.width, (int)size.height];
}

- (CGSize)displaySizeForView:(BRPreviewLayerView *)view {
	// display size is bounded to superview (UIScrollView) bounds
	return view.superview.bounds.size;
}

- (id)previewImageKeyForView:(BRPreviewLayerView *)view {
	return [(BRImagePreviewLayerView *)view.contentView imageURL];
}

- (UIImage *)previewImageForView:(BRPreviewLayerView *)view atSize:(CGSize)size {
	NSString *path = [self cachedImagePathForImageURL:[(BRImagePreviewLayerView *)view.contentView imageURL] atSize:size];
	if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
		return [[UIImage alloc] initWithContentsOfFile:path];
	}
	return nil;
}

- (UIImage *)renderPreviewImageForView:(BRPreviewLayerView *)view key:(id)key atSize:(CGSize)size {
	NSURL *imageURL = key;
	
	// scale the image...
	UIImage *img = [[UIImage alloc] initWithContentsOfFile:[imageURL path]];
	CGSize destSize = BRAspectSizeToFit(img.size, size);
	UIGraphicsBeginImageContext(destSize);
	[img drawInRect:CGRectMake(0, 0, destSize.width,destSize.height)];
	UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();

	// cache it...
	NSData *data = UIImagePNGRepresentation(scaledImage);
	NSString *cachePath = [self cachedImagePathForImageURL:imageURL atSize:size];
	[data writeToFile:cachePath atomically:YES];
	
	// return it
	return scaledImage;
}

#pragma mark - BRScrollerDelegate

- (CGFloat)uniformPageWidthForScroller:(BRScrollerView *)scroller {
	return scroller.bounds.size.width;
}

- (NSUInteger)numberOfPagesInScroller:(BRScrollerView *)scroller {
	return [imagePaths count];
}

- (UIView *)createReusablePageViewForScroller:(BRScrollerView *)scroller {
	BRZoomingImageView *zoomer = [[BRZoomingImageView alloc] initWithFrame:scroller.bounds];
	zoomer.imageView.delegate = self;
	zoomer.scrollDelegate = self;
	zoomer.imageView.imageContentView.delegate = self;
	zoomer.doubleTapToZoom = YES;
	return zoomer;
}

- (void)scroller:(BRScrollerView *)scroller
 willDisplayPage:(NSUInteger)index
			view:(UIView *)reusablePageView {
	BRZoomingImageView *zoomer = (BRZoomingImageView *)reusablePageView;
	zoomer.imageView.imageURL = imagePaths[index];
}

- (void)setTitleForImageView:(BRAsyncImageView *)view page:(NSUInteger)index {
	if ( view.loading ) {
		self.navigationItem.title = [NSString stringWithFormat:@"Image %lu loading...", (unsigned long)(index + 1)];
	} else {
		self.navigationItem.title = [NSString stringWithFormat:@"Image %lu", (unsigned long)(index + 1)];
	}
}

- (void)scroller:(BRScrollerView *)scroller didDisplayPage:(NSUInteger)index {
	BRZoomingImageView *zoomer = (BRZoomingImageView *)[scroller reusablePageViewAtIndex:index];
	prevButton.enabled = (index > 0);
	nextButton.enabled = (index + 1 < [self numberOfPagesInScroller:scroller]);
	[self setTitleForImageView:zoomer.imageView.imageContentView page:index];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)theScrollView withView:(UIView *)view {
	BRImagePreviewLayerView *imageView = (BRImagePreviewLayerView *)view;
	BRAsyncImageView *contentView = imageView.imageContentView;
	[contentView loadImage];
	[self setTitleForImageView:contentView page:[scrollView centerPageIndex]];
}

#pragma mark - BRAsyncImageViewDelegate

- (void)didDisplayAsyncImageInView:(BRAsyncImageView *)view {
	const NSUInteger pageIndex = [scrollView centerPageIndex];
	BRZoomingImageView *zoomer = (BRZoomingImageView *)[scrollView reusablePageViewAtIndex:pageIndex];
	BRAsyncImageView *centerImageView = zoomer.imageView.imageContentView;
	if ( centerImageView == view ) {
		// update title to reflect change in image status
		[self setTitleForImageView:centerImageView page:pageIndex];
	}
}

@end
