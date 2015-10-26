//
//  BRScrollerDelegate.h
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRScrollViewDelegate.h"

@class BRScrollerView;

NS_ASSUME_NONNULL_BEGIN

/**
 An enum of page destination results after a scoll animation will end.
 */
typedef enum {
	/** The scoll view will end up on the same page as it started on. */
	BRScrollerViewPageDestinationSame = 0,
	
	/** The scoll view will end up on the previous page (to the left, or to the right if the scroll view is configured with @c reverseLayoutOrder set to @c YES). */
	BRScrollerViewPageDestinationPrevious = -1,
	
	/** The scoll view will end up on the next page (to the right, or to the left if the scroll view is configured with @c reverseLayoutOrder set to @c YES). */
	BRScrollerViewPageDestinationNext = 1,
	
} BRScrollerViewPageDestination;

/**
 Delegate API for the @c BRScrollerView.
 
 A @c BRScrollerView is designed to display pages of content. Each @i page is a view created and
 configured by this delegate. There are many callback methods designed to provide support
 to the UI displaying the scroll view, for example to update labels or buttons to reflect
 the state of the scroller.
 
 Because @c BRScrollerView is itself the @c UIScrollViewDelegate to itself, this protocol also 
 conforms to @c BRScrollViewDelegate so that you can provide implementations for a subset of 
 @c UIScrollViewDelegate methods as well.

 @b Note when @c BRScrollerView is configured in @i infinite mode (the @c infinite property is @c YES)
 then all page index values can be translated to signed offsets by calling @c infinitePageOffsetForIndex:
 to obtain a relative page offset from a @i middle reference point in the infinite page index space.
 */
@protocol BRScrollerDelegate <BRScrollViewDelegate>

@required

/**
 Return the number of pages of content to display.
 
 @param scroller The scroll view requesting the page count.
 
 @return The number of pages of content the scroll view should display.
 */
- (NSUInteger)numberOfPagesInScroller:(BRScrollerView *)scroller;

/**
 Create a reusable page view. BRScrollerView will adjust the frame of this view automatically 
 to fit the bounds of the view. You don't need to set any autoresizing mask value on the view 
 returned here.
 
 @param scroller The scroll view.
 
 @return A reusable page view for the scroll view to manage.
 */
- (UIView *)createReusablePageViewForScroller:(BRScrollerView *)scroller;

/**
 Configure and otherwise prepare a single page for view "soon". The view might be for an offscreen page to the 
 left or right of the visible page, so that when scrolled the content is immediately available.
 
 @param scroller         The scroll view.
 @param index            The index of the page to prepare.
 @param reusablePageView The reusable page view, returned previously from a call to @c createReusablePageViewForScroller:.
 */
- (void)scroller:(BRScrollerView *)scroller willDisplayPage:(NSUInteger)index view:(UIView *)reusablePageView;

@optional

/**
 Return a uniform scrolling length for all pages; defaults to the scroll view's frame width.
 
 @param scroller The scroll view.
 
 @return The width of each page of content.
 */
- (CGFloat)uniformPageWidthForScroller:(BRScrollerView *)scroller;

/**
 Callback called as soon as a new page view enters the bounds of the scroller and becomes visible.
 Call @c reusablePageViewAtIndex: to access the reusable page view if needed.
 
 @param scroller The scroll view.
 @param index    The index of the page that has become visible.
 */
- (void)scroller:(BRScrollerView *)scroller didDisplayPage:(NSUInteger)index;

/**
 Callback called after a page view has stopped a scrolling animatition and @i settled on screen.
 Call @c reusablePageViewAtIndex: to access the reusable page view if needed.
 
 @param scroller The scroll view.
 @param index    The index of the page that has settled.
 */
- (void)scroller:(BRScrollerView *)scroller didSettleOnPage:(NSUInteger)index;

/**
 Callback called as soon as a visible page view starts to leave the bounds of the scroller to become hidden.
 Call @c reusablePageViewAtIndex: to access the reusable page view if needed.
 
 @param scroller The scroll view.
 @param index    The index of the page that will be leaving the screen.
 */
- (void)scroller:(BRScrollerView *)scroller willLeavePage:(NSUInteger)index;

/**
 Callback called after a visible page has completely left the bounds of the scroller and became hidden.
 Call @c reusablePageViewAtIndex: to access the reusable page view if needed.

 @param scroller The scroll view.
 @param index    The index of the page that has left the screen.
 */
- (void)scroller:(BRScrollerView *)scroller didLeavePage:(NSUInteger)index;

#pragma mark UIScrollViewDelegate-esque Support

/**
 Specialized callback when a page view is animating into a @i settled position, informing the receiver
 of the direction of the animation. The scroller's @c centerPageIndex method can be called to find out what
 the @i current visible page is.
 
 @param scroller    The scoll view.
 @param decelerate  @c YES if the scroll view is still animating and will decelerate into a final position.
 @param destination The destination the scroll view will reach when the animation comes to an end.
 */
- (void)scrollerDidEndDragging:(BRScrollerView *)scroller
				willDecelerate:(BOOL)decelerate
			   pageDestination:(BRScrollerViewPageDestination)destination;
@end

NS_ASSUME_NONNULL_END
