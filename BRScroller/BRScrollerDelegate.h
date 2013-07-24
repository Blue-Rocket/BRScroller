//
//  BRScrollerDelegate.h
//  BRScroller
//
//  A BRScroller is designed to display pages of content. Each "page" is a view created and
//  configured by this delegate. There are many callback methods designed to provide support
//  to the UI displaying the scroll view, for example to update labels or buttons to reflect
//  the state of the scroller.
//
//  NOTE when BRScrollerView is configured in "infinite" mode (i.e. the infinite property == YES)
//  then all page index values can be translated to signed offsets by calling infinitePageOffsetForIndex:
//  to obtain a relative page offset from a "middle" reference point in the infinite page index space.
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <Foundation/Foundation.h>

#import "BRScrollViewDelegate.h"

@class BRScrollerView;

typedef enum {
	BRScrollerViewPageDestinationSame = 0,
	BRScrollerViewPageDestinationPrevious = -1,
	BRScrollerViewPageDestinationNext = 1,
} BRScrollerViewPageDestination;

@protocol BRScrollerDelegate <BRScrollViewDelegate>

@required

// Return the number of pages of content to display.
- (NSUInteger)numberOfPagesInScroller:(BRScrollerView *)scroller;

// Create a reusable page view. BRScrollerView will adjust the frame of
// this view automatically to fit the bounds of the view. You don't need to set
// any autoresizingMask value on the view returned here.
- (UIView *)createReusablePageViewForScroller:(BRScrollerView *)scroller;

// configure and otherwise prepare a single page for view "soon". The page might not
// be going to be shown on screen yet.
- (void)scroller:(BRScrollerView *)scroller
 willDisplayPage:(NSUInteger)index
			view:(UIView *)reusablePageView;

@optional

// Return a uniform scrolling length for all pages; defaults to view bounds width
- (CGFloat)uniformPageWidthForScroller:(BRScrollerView *)scroller;

// callback called as soon as a new page view enters the bounds of the scroller, i.e. becomes visible
- (void)scroller:(BRScrollerView *)scroller didDisplayPage:(NSUInteger)index;

// callback called after a page view has stopped a scrolling animatition and "settled", i.e became visible
- (void)scroller:(BRScrollerView *)scroller didSettleOnPage:(NSUInteger)index;

// callback called as soon as a visible page view starts to leave the bounds of the scroller, i.e. become hidden
- (void)scroller:(BRScrollerView *)scroller willLeavePage:(NSUInteger)index;

// callback called after a visible page has completely left the bounds of the scroller, i.e. became hidden
- (void)scroller:(BRScrollerView *)scroller didLeavePage:(NSUInteger)index;

#pragma mark UIScrollViewDelegate-esque Support

// specialized callback when a page view is animating into a "settled" position, telling the receiver
// the direction of the animation. The scroller's centerPageIndex method can be called to find out what
// the "current" page is.
- (void)scrollerDidEndDragging:(BRScrollerView *)scroller
				willDecelerate:(BOOL)decelerate
			   pageDestination:(BRScrollerViewPageDestination)destination;
@end
