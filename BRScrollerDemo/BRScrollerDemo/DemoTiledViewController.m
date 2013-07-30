//
//  DemoTiledViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 7/17/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "DemoTiledViewController.h"

#import <BRScroller/BRScroller.h>
#import "DemoTiledView.h"
#import "DemoZoomingTiledView.h"

static const NSUInteger kNumPages = 10;

@interface DemoTiledViewController () <BRScrollerDelegate>
@end

@implementation DemoTiledViewController {
	BRScrollerView *scrollView;
}

@synthesize scrollView;

- (void)viewDidLoad {
    [super viewDidLoad];
	scrollView.scrollerDelegate = self;
	scrollView.pagingEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ( scrollView.loaded == NO ) {
		[scrollView reloadData];
	}
}

#pragma mark - BRScrollerDelegate

- (CGFloat)uniformPageWidthForScroller:(BRScrollerView *)scroller {
	return scroller.bounds.size.width;
}

- (NSUInteger)numberOfPagesInScroller:(BRScrollerView *)scroller {
	return kNumPages;
}

- (UIView *)createReusablePageViewForScroller:(BRScrollerView *)scroller {
	DemoZoomingTiledView *zoomer = [[DemoZoomingTiledView alloc] initWithFrame:scroller.bounds];
	zoomer.scrollDelegate = self;
	return zoomer;
}

- (void)scroller:(BRScrollerView *)scroller
 willDisplayPage:(NSUInteger)index
			view:(UIView *)reusablePageView {
	// nothing to do here
}

- (void)scroller:(BRScrollerView *)scroller didDisplayPage:(NSUInteger)index {
	self.navigationItem.title = [NSString stringWithFormat:@"Page %lu", (unsigned long)(index + 1)];
}

@end
