//
//  BRScrollerView.h
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

// the maximum allowable page index when infinite == YES
extern const NSUInteger kBRScrollerViewInfiniteMaximumPageIndex;

@protocol BRScrollerDelegate;

/**
 A horizontally-scrolling view that supports @i pages of content that are managed efficiently
 so that a large number of pages can be shown. It works very much like a @c UITableView does:
 the @c BRScrollerDelegate creates the reusable page views when asked by this view, and then
 configures the page view content when asked. Page views are recycled and reused as needed
 so that only as many as necessary are kept in memory at one time.
 
 It also supports an @i infinite scrolling mode. In this mode the delegate will not be asked
 to provide a page count and instead the scroll view will simply scroll as far as it can,
 up to a maximum page index @c kBRScrollerViewInfiniteMaximumPageIndex.
 */
@interface BRScrollerView : UIScrollView

/** The (required) delegate for providing page content. */
@property (nonatomic, weak) IBOutlet id<BRScrollerDelegate> scrollerDelegate;

/** If @c YES, display pages left-to-right in descending order, if @c NO then left-to-right in ascending order. */
@property (nonatomic, getter=isReverseLayoutOrder) BOOL reverseLayoutOrder;

/** Return @c YES if pages have been loaded and are currently cached. */
@property (nonatomic, readonly, getter=isLoaded) BOOL loaded;

/**
 Reload pages completely from the delegate, and display page @c 0.
 */
- (void)reloadData;

/**
 Reload pages from the delegate, centering on the specified page.
 
 @param index The page index to display after reloading the page content.
 */
- (void)reloadDataCenteredOnPage:(NSUInteger)index;

/** Release all cached reusable page views. */
- (void)releaseAllReusablePages;

/**
 Get the index of the center (visible) page.
 
 @return The center page index.
 */
- (NSUInteger)centerPageIndex;

/**
 Get the reusable page view for the center (visible) page. This is a shortcut for 
 @c [scroller reusablePageViewAtIndex:[scroller centerPageIndex]].
 
 @return The reusable page view, or @c nil if no pages are loaded.
 */
- (nullable __kindof UIView *)reusablePageViewForCenterPage;

/**
 Get a reusable page view at a specific index.
 
 @param viewIndex The index of the page to get.
 
 @return The reusable page view, or @c nil if the specified page is not currently loaded.
 */
- (nullable __kindof UIView *)reusablePageViewAtIndex:(NSUInteger)viewIndex;

/**
 Get the range of loaded reusable page views.
 
 @return The loaded page range.
 */
- (NSRange)loadedReusablePageRange;

/**
 Get an array of all loaded reusable page views.
 
 @return The array of all loaded page views.
 */
- (NSArray<__kindof UIView *> *)loadedReusablePages;

/// ----------------
/// @name Navigation
/// ----------------

/**
 Center the scroll view on a specific page.
 
 @param index    The index of the page to center on.
 @param animated Flag to animate the transition.
 */
- (void)gotoPage:(NSUInteger)index animated:(BOOL)animated;

/**
 Center the scroll view on the page immediately to the right, or if @c reverseLayoutOrder
 is @c YES immediately to the left.
 */
- (void)gotoNextPage;

/**
 Center the scroll view on the page immediately to the left, or if @c reverseLayoutOrder
 is @c YES immediately to the right.
 */
- (void)gotoPreviousPage;

/// -------------------
/// @name Infinite mode
/// -------------------

/**
 If @c YES, operate in @i infinite mode, where an approximation of infinite pages are supported.
 There are actually @c kBRScrollerViewInfiniteMaximumPageIndex pages supported, but in this mode the scroll view
 starts at a middle @i origin and you can scroll left or right, resulting in @i offset page values,
 for example page offset @c -1 (left of origin) or page offset @c 1 (right of origin). Use the
 @c infiniteOffsetForPageIndex: and @c pageIndexForInfiniteOffset: methods to translate the page
 index values passed to delegate methods (which are unsigned integers) to signed offset values.
 Scrolling left will stop at page index @c 0; scrolling right will stop at page index
 @c kBRScrollerViewInfiniteMaximumPageIndex. Setting to @c YES automatically hides the scroll bars.
 */
@property (nonatomic, getter = isInfinite) BOOL infinite;

/**
 When @c infinite is @c YES, this controls the maximum number of pages you can scroll continuously for
 before the scroll view stops. After stopping, the scroll view will reset its page space and
 scrolling can continue. The scroll view will reset its page space any time scrolling stops,
 so under most situations where users scroll the scroll view will never appear to stop scrolling.
 */
@property (nonatomic, assign) UInt16 infiniteSpacePageRadius;

/**
 Translate an infinite index into a signed page offset.
 
 @param index The infinite page index to translate.
 
 @return The signed page offset from the center of the infinite page space.
 */
- (NSInteger)infiniteOffsetForPageIndex:(NSUInteger)index;

/**
 Translate a signed page offset into an infinite page index.
 
 @param offset The page offset to translate.
 
 @return The infinite page index.
 */
- (NSUInteger)pageIndexForInfiniteOffset:(NSInteger)offset;

@end

NS_ASSUME_NONNULL_END
