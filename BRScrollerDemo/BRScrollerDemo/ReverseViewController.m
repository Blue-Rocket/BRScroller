//
//  ReverseViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 7/25/13.
//  Copyright (c) 2013 Blue Rocket. All rights reserved.
//

#import "ReverseViewController.h"

#import <BRScroller/BRScroller.h>

@interface ReverseViewController () <BRScrollerDelegate>
@end

@implementation ReverseViewController {
	BRScrollerView *scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	scrollView = [[BRScrollerView alloc] initWithFrame:self.view.bounds];
	scrollView.scrollerDelegate = self;
	scrollView.pagingEnabled = YES;
	scrollView.reverseLayoutOrder = YES;
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:scrollView];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	scrollView = nil;
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
	return 10;
}

- (UIView *)createReusablePageViewForScroller:(BRScrollerView *)scroller {
	UIView *pageView = [[UIView alloc] initWithFrame:scroller.bounds];
	pageView.backgroundColor = [UIColor whiteColor];
	UILabel *pageNumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 50)];
	[pageView addSubview:pageNumber];
	pageNumber.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin
								   | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
	pageNumber.textColor = [UIColor orangeColor];
	pageNumber.font = [UIFont boldSystemFontOfSize:21];
	pageNumber.layer.borderColor = [UIColor orangeColor].CGColor;
	pageNumber.layer.borderWidth = 2.0;
	pageNumber.textAlignment = NSTextAlignmentCenter;
	pageNumber.backgroundColor = [UIColor grayColor];
	pageNumber.center = CGPointMake(pageView.bounds.size.width * 0.5, pageView.bounds.size.height * 0.5);
	
	return pageView;
}

- (void)scroller:(BRScrollerView *)scroller
 willDisplayPage:(NSUInteger)index
			view:(UIView *)reusablePageView {
	UILabel *label = reusablePageView.subviews[0];
	label.text = [NSString stringWithFormat:@"%lu", (unsigned long)(index + 1)];
}

- (void)scroller:(BRScrollerView *)scroller didDisplayPage:(NSUInteger)index {
	if ( scroller == scrollView ) {
		self.navigationItem.title = [NSString stringWithFormat:@"%lu", (unsigned long)(index + 1)];
	}
}

@end
