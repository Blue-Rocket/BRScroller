//
//  BRScrollerView.h
//  BRScroller
//
//  A horizontally-scrolling view that supports "pages" of content that are managed efficiently
//  so that a large number of "pages" can be shown. It works very much like a UITableView does:
//  the BRScrollerDelegate creates the reusable page views when asked by this view, and then
//  configures the page view content when asked. Page views are recycled and reused as needed
//  so that only as many as necessary are kept in memory at one time.
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

@protocol BRScrollerDelegate;

@interface BRScrollerView : UIScrollView

// the (required) delegate for providing page content
@property (nonatomic, weak) id<BRScrollerDelegate> scrollerDelegate;

// if YES, display pages left-to-right in descending order, if NO then left-to-right in ascending order
@property (nonatomic, getter=isReverseLayoutOrder) BOOL reverseLayoutOrder;

// If YES, operate in "infinite" mode, where an approximation of infinite pages are supported;
// there are of course at most NSUIntegerMax pages supported, but in this mode the scroll view
// starts at an "origin" and you can scroll left or right, resulting in "offset" page values,
// for example page offset -1 (left of origin) or page offset 1 (right of origin). Use the
// infiniteOffsetForPageIndex: and pageIndexForInfiniteOffset: methods to translate the page
// index values passed to delegate methods (which are unsigned integers) to signed offset values.
// Setting to YES automatically hides the scroll bars.
@property (nonatomic, getter = isInfinite) BOOL infinite;

// return YES if pages have been loaded and are currently cached
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

// reload pages completely from the delegate, and display page 0
- (void)reloadData;

// reload pages from the delegate, centering on the specified page
- (void)reloadDataCenteredOnPage:(NSUInteger)index;

// release all cached reusable page views
- (void)releaseAllReusablePages;

// get information on the center-most reusable page
- (NSUInteger)centerPageIndex;
- (UIView *)reusablePageViewForCenterPage;

// get a reusable page at the specified index, or nil if that page is not currently loaded
- (UIView *)reusablePageViewAtIndex:(NSUInteger)viewIndex;

// get the range of loaded reusable pages
- (NSRange)loadedReusablePageRange;

// get all reusable pages
- (NSArray *)loadedReusablePages;

// jump to a specific page
- (void)gotoPage:(NSUInteger)index animated:(BOOL)animated;

// jump to the "next" page, which depending on the reverseLayoutOrder property will
// cause the scroll view to move left or right a single page
- (void)gotoNextPage;

// jump to the "previous" page, which depending on the reverseLayoutOrder property will
// cause the scroll view to move right or left a single page
- (void)gotoPreviousPage;

// translate between "infinite" page offsets and page index values
- (NSInteger)infiniteOffsetForPageIndex:(NSUInteger)index;
- (NSUInteger)pageIndexForInfiniteOffset:(NSInteger)offset;

@end
