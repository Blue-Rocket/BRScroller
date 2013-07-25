//
//  InfiniteViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 7/24/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "InfiniteViewController.h"

#import <BRScroller/BRScroller.h>

static const CGFloat kThumbWidth = 120;

@interface InfiniteViewController () <BRScrollerDelegate>
@end

@implementation InfiniteViewController {
	BRScrollerView *scrollView;
	BRScrollerView *thumbView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	scrollView = [[BRScrollerView alloc] initWithFrame:self.view.bounds];
	scrollView.scrollerDelegate = self;
	scrollView.pagingEnabled = YES;
	scrollView.infinite = YES;
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:scrollView];

	thumbView = [[BRScrollerView alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 120, self.view.bounds.size.width, 120)];
	thumbView.scrollerDelegate = self;
	thumbView.infinite = YES;
	thumbView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
	thumbView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
	[self.view addSubview:thumbView];
	
	self.navigationItem.title = NSStringFromClass([self class]);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self
																						   action:@selector(done:)];
	UIBarButtonItem *prevButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"infiniti.minus.label", nil) style:UIBarButtonItemStylePlain target:self action:@selector(goInfinitiMinus:)];
	UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"infiniti.plus.label", nil) style:UIBarButtonItemStylePlain target:self action:@selector(goInfinitiPlus:)];
	NSDictionary *textAttr = @{ UITextAttributeFont : [UIFont boldSystemFontOfSize:18] };
	[prevButton setTitleTextAttributes:textAttr forState:UIControlStateNormal];
	[nextButton setTitleTextAttributes:textAttr forState:UIControlStateNormal];
	self.navigationItem.leftBarButtonItems = @[prevButton, nextButton];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	scrollView = nil;
	thumbView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ( scrollView.loaded == NO ) {
		[scrollView reloadData];
		[thumbView reloadData];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}

- (IBAction)done:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)goInfinitiMinus:(id)sender {
	[scrollView gotoPage:0 animated:YES];
	[thumbView gotoPage:0 animated:YES];
}

- (IBAction)goInfinitiPlus:(id)sender {
	[scrollView gotoPage:NSUIntegerMax animated:YES];
	[thumbView gotoPage:NSUIntegerMax animated:YES];
}

- (IBAction)gotoPage:(UIGestureRecognizer *)sender {
	NSUInteger destPage = sender.view.tag;
	[scrollView gotoPage:destPage animated:YES];
}

#pragma mark - BRScrollerDelegate

- (CGFloat)uniformPageWidthForScroller:(BRScrollerView *)scroller {
	CGFloat result;
	if ( scroller == scrollView ) {
		result = scroller.bounds.size.width;
	} else {
		result = kThumbWidth;
	}
	return result;
}

- (NSUInteger)numberOfPagesInScroller:(BRScrollerView *)scroller {
	return NSUIntegerMax;
}

- (UIView *)createReusablePageViewForScroller:(BRScrollerView *)scroller {
	UIView *pageView = [[UIView alloc] initWithFrame:scroller.bounds];
	pageView.backgroundColor = (scroller == scrollView ? [UIColor whiteColor] : [UIColor clearColor]);
	UILabel *pageNumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
	[pageView addSubview:pageNumber];
	pageNumber.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin
								   | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
	pageNumber.textColor = [UIColor orangeColor];
	pageNumber.font = [UIFont boldSystemFontOfSize:21];
	pageNumber.layer.borderColor = [UIColor orangeColor].CGColor;
	pageNumber.layer.borderWidth = 2.0;
	pageNumber.textAlignment = NSTextAlignmentCenter;
	pageNumber.adjustsFontSizeToFitWidth = YES;
	pageNumber.backgroundColor = [UIColor grayColor];
	pageNumber.center = CGPointMake(pageView.bounds.size.width * 0.5, pageView.bounds.size.height * 0.5);

	// add a tap recognizer, so tapping on "thumb" navigates full scroller to associated page
	UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(gotoPage:)];
	tap.numberOfTapsRequired = 1;
	[pageView addGestureRecognizer:tap];
	
	return pageView;
}

- (void)scroller:(BRScrollerView *)scroller
 willDisplayPage:(NSUInteger)index
			view:(UIView *)reusablePageView {
	UILabel *label = reusablePageView.subviews[0];
	label.text = [NSString stringWithFormat:@"%ld", (long)[scroller infiniteOffsetForPageIndex:index]];
	reusablePageView.tag = index; // simple way to know index in gotoPage:
}

- (void)scroller:(BRScrollerView *)scroller didDisplayPage:(NSUInteger)index {
	if ( scroller == scrollView ) {
		self.navigationItem.title = [NSString stringWithFormat:@"Page %ld", (long)[scroller infiniteOffsetForPageIndex:index]];
	}
}

- (void)scroller:(BRScrollerView *)scroller didSettleOnPage:(NSUInteger)index {
	log4Debug(@"Settled on page %ld", (long)[scroller infiniteOffsetForPageIndex:index]);
}

@end
