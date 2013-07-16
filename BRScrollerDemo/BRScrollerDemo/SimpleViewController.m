//
//  SimpleViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 7/16/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "SimpleViewController.h"

#import <BRScroller/BRScroller.h>

static const NSUInteger kNumPages = 10;

@interface SimpleViewController () <BRScrollerDelegate>
@end

@implementation SimpleViewController {
	BRScrollerView *scrollView;
}

@synthesize scrollView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ( (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) ) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	scrollView.scrollerDelegate = self;
	scrollView.pagingEnabled = YES;
	self.navigationItem.title = NSStringFromClass([self class]);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self
																						   action:@selector(done:)];
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
	return kNumPages;
}

- (UIView *)createReusablePageViewForScroller:(BRScrollerView *)scroller {
	UIView *pageView = [[UIView alloc] initWithFrame:scroller.bounds];
	pageView.backgroundColor = [UIColor darkGrayColor];
	pageView.layer.borderColor = [UIColor yellowColor].CGColor;
	pageView.layer.borderWidth = 1.0;
	UILabel *pageNumber = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
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

@end
