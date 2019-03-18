//
//  MultiViewController.m
//  BRScrollerDemo
//
//  Created by Matt on 7/17/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "MultiViewController.h"

#import <BRScroller/BRScroller.h>

static const NSUInteger kNumPages = 10;
static const CGFloat kThumbWidth = 180;

@interface MultiViewController () <BRScrollerDelegate>
@end

@implementation MultiViewController {
	BRScrollerView *scrollView;
	BRScrollerView *thumbView;
}

@synthesize scrollView, thumbView;

- (void)viewDidLoad {
    [super viewDidLoad];
	scrollView.scrollerDelegate = self;
	scrollView.pagingEnabled = YES;
	thumbView.scrollerDelegate = self;
	UIBarButtonItem *toggle = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"hide.thumbs", nil)
																			 style:UIBarButtonItemStylePlain
																			target:self
																			action:@selector(toggleThumbs:)];
	NSDictionary *textAttr = @{ UITextAttributeFont : [UIFont systemFontOfSize:27] };
	[toggle setTitleTextAttributes:textAttr forState:UIControlStateNormal];
	self.navigationItem.leftBarButtonItem = toggle;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	if ( scrollView.loaded == NO ) {
		[scrollView reloadData];
		[thumbView reloadData];
	}
}

- (IBAction)gotoPage:(UIGestureRecognizer *)sender {
	NSUInteger destPage = sender.view.tag;
	[scrollView gotoPage:destPage animated:YES];
}

- (IBAction)toggleThumbs:(UIBarButtonItem *)sender {
	const CGPoint thumbViewOrigin = [self.view convertPoint:thumbView.frame.origin fromView:thumbView.superview];
	if ( CGRectContainsPoint(self.view.bounds, thumbViewOrigin) ) {
		// hide
		[UIView animateWithDuration:0.4 animations:^{
            const CGFloat destY = CGRectGetMaxY(self.view.bounds) + self->thumbView.bounds.size.height * 0.5 + 1;
            self->thumbView.center = CGPointMake(self->thumbView.center.x, [self.view convertPoint:CGPointMake(0, destY) toView:self->thumbView.superview].y);
		}];
		sender.title = NSLocalizedString(@"show.thumbs", nil);
	} else {
		// show
		[UIView animateWithDuration:0.4 animations:^{
            const CGFloat destY = CGRectGetMaxY(self.view.bounds) - self->thumbView.bounds.size.height * 0.5;
            self->thumbView.center = CGPointMake(self->thumbView.center.x, [self.view convertPoint:CGPointMake(0, destY) toView:self->thumbView.superview].y);
		}];
		sender.title = NSLocalizedString(@"hide.thumbs", nil);
	}
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
	return kNumPages;
}

- (UIView *)createReusablePageViewForScroller:(BRScrollerView *)scroller {
	UIView *pageView = [[UIView alloc] initWithFrame:(scroller == scrollView ? scroller.bounds : CGRectMake(0, 0, kThumbWidth, scroller.bounds.size.height))];
	pageView.backgroundColor = (scroller == scrollView ? [UIColor whiteColor] : [UIColor clearColor]);
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
	label.text = [NSString stringWithFormat:@"%lu", (unsigned long)(index + 1)];
	reusablePageView.tag = index; // simple way to know index in gotoPage:
}

- (void)scroller:(BRScrollerView *)scroller didDisplayPage:(NSUInteger)index {
	if ( scroller == scrollView ) {
		self.navigationItem.title = [NSString stringWithFormat:@"Page %lu", (unsigned long)(index + 1)];
	}
}

@end
