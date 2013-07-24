//
//  InfiniteViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 7/24/13.
//  Copyright (c) 2013 Blue Rocket. All rights reserved.
//

#import "InfiniteViewController.h"

#import <BRScroller/BRScroller.h>

@interface InfiniteViewController () <BRScrollerDelegate>

@end

@implementation InfiniteViewController {
	BRScrollerView *scrollView;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ( (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) ) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	scrollView = [[BRScrollerView alloc] initWithFrame:self.view.bounds];
	scrollView.scrollerDelegate = self;
	scrollView.pagingEnabled = YES;
	scrollView.infinite = YES;
	[self.view addSubview:scrollView];

	self.navigationItem.title = NSStringFromClass([self class]);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self
																						   action:@selector(done:)];
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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}

- (IBAction)done:(id)sender {
	[self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - BRScrollerDelegate

- (CGFloat)uniformPageWidthForScroller:(BRScrollerView *)scroller {
	return scroller.bounds.size.width;
}

- (NSUInteger)numberOfPagesInScroller:(BRScrollerView *)scroller {
	return NSUIntegerMax;
}

- (UIView *)createReusablePageViewForScroller:(BRScrollerView *)scroller {
	UIView *pageView = [[UIView alloc] initWithFrame:scroller.bounds];
	pageView.backgroundColor = [UIColor darkGrayColor];
	pageView.layer.borderColor = [UIColor yellowColor].CGColor;
	pageView.layer.borderWidth = 1.0;
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
	label.text = [NSString stringWithFormat:@"%ld", (long)([scroller infiniteOffsetForPageIndex:index])];
}

@end
