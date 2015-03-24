//
//  BRScrollerView.m
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRScrollerView.h"

#import "BRScrollerDelegate.h"
#import "BRScrollerLogging.h"
#import "BRScrollerUtilities.h"

const NSUInteger kBRScrollerViewInfiniteMaximumPageIndex = NSUIntegerMax - 1; // to account for translating to NSInteger for maximum page

static const NSUInteger kInfiniteScrollOrigin = 256;
static const NSUInteger kInfiniteOrigin = NSIntegerMax;

@interface BRScrollerView () <UIScrollViewDelegate>
@end

@implementation BRScrollerView {
	__weak id<BRScrollerDelegate> scrollerDelegate;
	BOOL loaded;
	BOOL reverseLayoutOrder;
	BOOL centeringReload;
	BOOL adjustingFrame;
	BOOL scrolling;
	BOOL adjustingContent;
	BOOL infinite;
	NSUInteger layoutGotoPage;
	
	CGFloat pageWidth;
	NSUInteger pageCount;
	int lastScrollDirection;
	CGFloat lastScrollOffset;
	NSUInteger head;
	NSUInteger centerIndex;
	NSUInteger infinitePageOffset;
	NSMutableArray *pages;
}

@synthesize scrollerDelegate, loaded, reverseLayoutOrder;
@synthesize infinite;

- (id)initWithFrame:(CGRect)frame {
	if ( (self = [super initWithFrame:frame]) ) {
		[self initializeBRScrollerViewDefaults];
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.scrollEnabled = YES;
		self.userInteractionEnabled = YES;
		self.multipleTouchEnabled = YES;
		self.showsVerticalScrollIndicator = NO;
		self.opaque = YES;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ( (self = [super initWithCoder:aDecoder]) ) {
		[self initializeBRScrollerViewDefaults];
	}
	return self;
}

- (void)initializeBRScrollerViewDefaults {
	[super setDelegate:self]; // i am my own UIScrollViewDelegate
	head = 0;
	centerIndex = 0;
	lastScrollDirection = 0;
	lastScrollOffset = 0;
	infinitePageOffset = 0;
	pages = [[NSMutableArray alloc] init];
	layoutGotoPage = NSNotFound;
}

#pragma mark - Accessors

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate {
	if ( delegate != nil ) {
		NSAssert(NO, @"You may not set a scroll view delegate on a %@", NSStringFromClass([self class]));
	}
}

- (void)setInfinite:(BOOL)value {
	infinite = value;
	if ( value == YES ) {
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
	}
}

#pragma mark Public API

- (NSUInteger)pageIndexForInfiniteOffset:(NSInteger)offset {
	return kInfiniteOrigin + offset;
}

- (NSInteger)infiniteOffsetForPageIndex:(NSUInteger)index {
	return (index == kInfiniteOrigin
			? (NSInteger)0
			: (index > kInfiniteOrigin
			   ? (NSInteger)(index - kInfiniteOrigin)
			   : -(NSInteger)(kInfiniteOrigin - index)));
}

- (NSUInteger)calculateInfinitePageOffsetForCenterIndex:(NSUInteger)index {
	if ( infinite == NO ) {
		return 0;
	}
	if ( index < kInfiniteScrollOrigin ) {
		return 0;
	}
	if ( index >= (kBRScrollerViewInfiniteMaximumPageIndex - kInfiniteScrollOrigin * 2) ) {
		return (kBRScrollerViewInfiniteMaximumPageIndex - kInfiniteScrollOrigin * 2);
	}
	return (index - kInfiniteScrollOrigin);
}

- (void)reloadDataCenteredOnPage:(NSUInteger)index {
	if ( infinite == YES && index > kBRScrollerViewInfiniteMaximumPageIndex ) {
		index = kBRScrollerViewInfiniteMaximumPageIndex;
	}
	// disable implicit animation here, so we avoid a "stretching" effect
	[self cachePageWidth];
	[self cachePageCount];
	[CATransaction begin]; {
		[CATransaction setDisableActions:YES];
		infinitePageOffset = [self calculateInfinitePageOffsetForCenterIndex:index];
		CGFloat xOffset = [self scrollOffsetForPageIndex:index];
		loaded = NO;
		centeringReload = YES;
		[self setContentOffset:CGPointMake(xOffset, 0) animated:NO];
		centeringReload = NO;
		[self reloadDataInternal];
		loaded = YES;
	} [CATransaction commit];
	[self handleDidSettle];
}

- (void)reloadData {
	[self reloadDataCenteredOnPage:(infinite ? [self pageIndexForInfiniteOffset:0] : 0)];
}

- (void)releaseAllReusablePages {
	[self releaseAllContainers];
}

- (UIView *)reusablePageViewForCenterPage {
	return [self reusablePageViewAtIndex:centerIndex];
}

- (UIView *)reusablePageViewAtIndex:(const NSUInteger)viewIndex {
	UIView *container = [self containerViewForIndex:viewIndex];
	NSArray *sv = [container subviews];
	return ([sv count] < 1 ? nil : [sv objectAtIndex:0]);
}

- (void)gotoPage:(const NSUInteger)index animated:(BOOL)animated {
	const BOOL crossingInfiniteBounds = (infinite == NO ? NO : (index < infinitePageOffset || index > (infinitePageOffset + pageCount)));
	if ( crossingInfiniteBounds ) {
		// cannot animate easily because we cross infinite bounds :-(
		log4Info(@"Crossing infinite boundary; animation disabled implicitly.");
		[self reloadDataCenteredOnPage:index];
		return;
	}
    CGFloat xOffset = [self scrollOffsetForPageIndex:index];
	if ( !BRFloatsAreEqual(xOffset, self.contentOffset.x) ) {
		if ( !animated ) {
			centeringReload = YES;
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
		}
		[self setContentOffset:CGPointMake(xOffset, 0) animated:animated];
		if ( !animated ) {
			scrolling = NO;
			centeringReload = NO;
			[self layoutForCurrentScrollOffset];
			[CATransaction commit];
			if ( adjustingFrame == NO && (centerIndex < pageCount || infinite == YES)
				&& [scrollerDelegate respondsToSelector:@selector(scroller:didDisplayPage:)] ) {
				[scrollerDelegate scroller:self didDisplayPage:centerIndex];
			}
		}
	}
}

- (NSArray *)loadedReusablePages {
	NSMutableArray *result = [NSMutableArray arrayWithCapacity:[pages count]];
	for ( UIView *container in pages ) {
		NSArray *sv = [container subviews];
		if ( [sv count] > 0 ) {
			[result addObject:[sv objectAtIndex:0]];
		}
	}
	return result;
	
}

- (NSRange)loadedReusablePageRange {
	return NSMakeRange(head, [pages count]);
}

- (NSUInteger)centerPageIndex {
	return centerIndex;
}

- (void)gotoNextPage {
	NSUInteger currPage = [self centerPageIndex];
	if ( currPage + 1 < pageCount ) {
		[self gotoPage:currPage + 1 animated:YES];
	}
}

- (void)gotoPreviousPage {
	NSUInteger currPage = [self centerPageIndex];
	if ( currPage > 0 ) {
		[self gotoPage:currPage - 1 animated:YES];
	}
}

#pragma mark - Layout

- (void)adjustContentSizeForViewSize:(CGSize)size atPageIndex:(NSUInteger)currIndex {
	layoutGotoPage = currIndex;
	[self setNeedsLayout];
}

- (void)setFrame:(CGRect)frame {
	const CGRect oldFrame = self.frame;
	const NSUInteger currIndex = [self centerPageIndex];
	[super setFrame:frame];
	if ( loaded && layoutGotoPage == NSNotFound && CGSizeEqualToSize(oldFrame.size, frame.size) == NO ) {
		// automatically go back to former page index
		[self adjustContentSizeForViewSize:frame.size atPageIndex:currIndex];
	}
}

- (void)setBounds:(CGRect)bounds {
	const CGRect oldBounds = self.bounds;
	const NSUInteger currIndex = [self centerPageIndex];
	[super setBounds:bounds];
	if ( loaded && layoutGotoPage == NSNotFound && CGSizeEqualToSize(oldBounds.size, bounds.size) == NO ) {
		// automatically go back to former page index
		[self adjustContentSizeForViewSize:bounds.size atPageIndex:currIndex];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// During rotation, here is where we'll re-layout our pages for the new dimensions of the scroll 
	// We do this by checking if the contentSize differs from what we calculate *should* be the contentSize
	// based on the current view bounds... if it doesn't match the epxected size, we re-lay out the pages.
	
	if ( layoutGotoPage != NSNotFound ) {
		adjustingFrame = YES;
		CGFloat height = self.bounds.size.height;
		[self cachePageWidth];
		[self cachePageCount];
		CGFloat width = pageCount * pageWidth;
		CGSize expectedContentSize = CGSizeMake(width, height);
		adjustingContent = YES;
		log4Debug(@"Adjusting content size from %@ to %@", NSStringFromCGSize(self.contentSize), NSStringFromCGSize(expectedContentSize));
		self.contentSize = expectedContentSize;
		adjustingContent = NO;
		[self gotoPage:layoutGotoPage animated:NO];
		[self layoutContainersForHead:head];
		layoutGotoPage = NSNotFound;
		adjustingFrame = NO;
	}
}

- (void)cachePageWidth {
	pageWidth = ([scrollerDelegate respondsToSelector:@selector(uniformPageWidthForScroller:)]
				 ? [scrollerDelegate uniformPageWidthForScroller:self]
				 : self.bounds.size.width);
}

- (void)cachePageCount {
	pageCount = (infinite
				 ? (kInfiniteScrollOrigin * 2 + 1) // + 1 so we have an actual center origin
				 : [scrollerDelegate numberOfPagesInScroller:self]);
}

- (NSUInteger)containerCountForViewWidth:(const CGFloat)viewWidth {
	return MIN(pageCount, (ceil(viewWidth / pageWidth) + 2)); // +2 for adjacent containers (left + right)
}

- (CGFloat)scrollOffsetForPageIndex:(const NSUInteger)index {
	return [self scrollOffsetForPageIndex:index pageWidth:pageWidth pageCount:pageCount];
}

- (CGFloat)scrollOffsetForPageIndex:(NSUInteger)index pageWidth:(const CGFloat)thePageWidth pageCount:(const NSUInteger)thePageCount {
	if ( infinite == NO && index >= thePageCount ) {
		index = 0; // force to page 1
	}
	if ( infinite == YES ) {
		index -= infinitePageOffset;
		//NSInteger pageOffset = [self infiniteOffsetForPageIndex:index];
		//index = kInfiniteScrollOrigin / 2 + pageOffset;
	}
	CGFloat centerOffset = floor((self.bounds.size.width - thePageWidth) * 0.5);
	return (reverseLayoutOrder
			? ((thePageCount * thePageWidth) - ((CGFloat)(index + 1) * thePageWidth) + centerOffset)
			: (CGFloat)index * thePageWidth) - centerOffset;
}

- (void)releaseAllContainers {
	[pages makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[pages removeAllObjects];
}

- (UIView *)containerViewForIndex:(NSUInteger)index {
	if ( infinite == YES ) {
		index -= infinitePageOffset;
	}
	if ( index < head || (head + [pages count]) <= index ) {
		// page not currently loaded
		return nil;
	}
	UIView *container = [pages objectAtIndex:(index - head)];
	return container;
}

- (void)layoutContainersForHead:(NSUInteger)newHead {
	// check if we can shift any curent containers
	NSRange reloadDataRange = NSMakeRange(0, 0);
	if ( newHead > head && newHead < (head + [pages count])  ) {
		// scrolling right, shift
		NSUInteger shiftLen = newHead - head;
		reloadDataRange.location = [pages count] - shiftLen;
		reloadDataRange.length = shiftLen;
		for ( NSUInteger i = shiftLen; i < [pages count]; i++ ) {
			log4Trace(@"Swapping page %lu and %lu", (unsigned long)i, (unsigned long)(i - shiftLen));
			[pages exchangeObjectAtIndex:i withObjectAtIndex:(i - shiftLen)];
		}
	} else if ( newHead < head && (head - newHead) < [pages count] ) {
		// scrolling left, shift
		NSUInteger shiftLen = head - newHead;
		reloadDataRange.length = shiftLen;
		for ( NSInteger i = ([pages count] - shiftLen - 1); i >= 0; i-- ) {
			log4Trace(@"Swapping page %lu and %lu", (unsigned long)i, (unsigned long)(i+shiftLen));
			[pages exchangeObjectAtIndex:i withObjectAtIndex:(i+shiftLen)];
		}
	} else {
		// reload everything, no shifing
		reloadDataRange.length = [pages count];
	}
	const CGFloat pageHeight = self.bounds.size.height;
	for ( NSUInteger i = reloadDataRange.location; i < (reloadDataRange.location + reloadDataRange.length); i++ ) {
		UIView *container = (UIView *)[pages objectAtIndex:i];
		CGFloat xOffset = (reverseLayoutOrder
						   ? ((pageCount * pageWidth) - ((newHead + i + 1) * pageWidth))
						   : ((newHead + i) * pageWidth));
		log4Trace(@"Moving container %lu (page %lu) from %@ to %@", (unsigned long)i, (unsigned long)(newHead + i + infinitePageOffset),
				  NSStringFromCGRect(container.frame), NSStringFromCGRect(CGRectMake(xOffset, 0, pageWidth, pageHeight)));
		container.center = CGPointMake(xOffset + (pageWidth / 2.0), (pageHeight / 2.0));
		if ( adjustingFrame ) {
			container.bounds = CGRectMake(0, 0, pageWidth, pageHeight);
			UIView *page = [container.subviews objectAtIndex:0];
			if ( !CGSizeEqualToSize(page.bounds.size, container.bounds.size) ) {
				page.frame = CGRectMake(0, 0, pageWidth, pageHeight);
			}
		} else {
			[scrollerDelegate scroller:self willDisplayPage:(newHead + i + infinitePageOffset) view:[container.subviews objectAtIndex:0]];
		}
	}
	
	head = newHead;
}

- (NSUInteger)calculateHeadForPageWidth:(const CGFloat)thePageWidth numContainers:(const NSUInteger)containerCount {
	// we change head pointer when scrolling past half-way width of pages, so swapping them around
	// does not affect visible pages
	const CGFloat scrollOffset = (reverseLayoutOrder
							? (CGFloat)(pageCount * pageWidth) - self.contentOffset.x - self.bounds.size.width
							: self.contentOffset.x);
	const CGFloat pageOffset = (scrollOffset - (thePageWidth / 2.0)) / thePageWidth;
	const NSUInteger h = MIN(pageCount - containerCount, (NSUInteger)MAX(0.0, floor(pageOffset)));
	log4Trace(@"offset %f, pageOffset = %f, pageCount = %lu, head = %lu, newHead = %lu", scrollOffset, pageOffset,
			  (unsigned long)containerCount, (unsigned long)head, (unsigned long)h);
	return h;
}

- (NSUInteger)calculateCenterForPageWidth:(const CGFloat)thePageWidth numContainers:(const NSUInteger)containerCount {
	// calculate "center" visible page, and report that. this really designed
	// for "paging" mode, where pages are full width of this view's bounds
	CGFloat xOffset = (reverseLayoutOrder
					   ? ((pageCount * pageWidth) - self.contentOffset.x - (self.bounds.size.width / 2.0))
					   : (self.contentOffset.x + (self.bounds.size.width / 2.0)));
	NSUInteger c = MIN(pageCount, (NSUInteger)MAX(0.0, floor(xOffset / thePageWidth)));
	if ( infinite == YES ) {
		c += infinitePageOffset;
	}
	log4Trace(@"offset %f, pageCount = %lu, center = %lu, newCenter = %lu", self.contentOffset.x,
			  (unsigned long)containerCount, (unsigned long)centerIndex, (unsigned long)c);
	return c;
}

- (void)recalculateScrollIndexesForNumberOfContainers:(const NSUInteger)containerCount {
	head = [self calculateHeadForPageWidth:pageWidth numContainers:containerCount];
	centerIndex = [self calculateCenterForPageWidth:pageWidth numContainers:containerCount];
}

- (void)handleInfiniteShuffle {
	const NSUInteger newInfinitePageOffset = [self calculateInfinitePageOffsetForCenterIndex:centerIndex];
	if ( newInfinitePageOffset != infinitePageOffset ) {
		const CGRect viewBounds = self.bounds;
		const CGFloat oldScrollOffset = self.contentOffset.x;
		const CGFloat perfectOffsetDiff = oldScrollOffset - [self scrollOffsetForPageIndex:centerIndex];
		const NSUInteger oldHead = head;
		const BOOL reloadLeft = oldHead == 0;
		const BOOL reloadRight = oldHead == (pageCount - [pages count]);
		[CATransaction begin]; {
			[CATransaction setDisableActions:YES];
			infinitePageOffset = newInfinitePageOffset;
			CGFloat xOffset = [self scrollOffsetForPageIndex:centerIndex] + perfectOffsetDiff;
			centeringReload = YES;
			[self setContentOffset:CGPointMake(xOffset, 0) animated:NO];
			centeringReload = NO;
			NSUInteger newHead = [self calculateHeadForPageWidth:pageWidth numContainers:[pages count]];
			if ( reloadLeft || reloadRight ) {
				// we've scrolled to the end of our current scroll bounds, so we need to shift the views over 1
				// so we don't reload views we've already configured. To do that, we trick
				// layoutContainersForHead: by setting head, so it shifts appropriately.
				head = newHead + (reloadLeft ? 1 : -1);
				[self layoutContainersForHead:newHead];
			} else {
				head = newHead;
			}
			for ( NSUInteger i = 0; i < [pages count]; i++ ) {
				const NSUInteger pageIndex = head + i;
				UIView *container = (UIView *)[pages objectAtIndex:i];
				CGFloat xOffset = (reverseLayoutOrder
								   ? ((pageCount * pageWidth) - ((pageIndex + 1) * pageWidth))
								   : (pageIndex * pageWidth));
				CGPoint newCenter = CGPointMake(xOffset + pageWidth * 0.5, viewBounds.size.height * 0.5);
				log4Trace(@"Moving container %lu (page %lu) from %@ to %@", (unsigned long)i, (unsigned long)pageIndex,
						  NSStringFromCGPoint(container.center), NSStringFromCGPoint(newCenter));
				container.center = newCenter;
			}
		} [CATransaction commit];
	}
}

- (void)handleDidSettle {
	scrolling = NO;
	if ( self.pagingEnabled && [scrollerDelegate respondsToSelector:@selector(scroller:didSettleOnPage:)] ) {
		[scrollerDelegate scroller:self didSettleOnPage:centerIndex];
	}
	if ( infinite == YES ) {
		[self handleInfiniteShuffle];
	}
}

- (NSUInteger)centerContainerIndex {
	return floorf([pages count] / 2.0);
}

- (void)reloadDataInternal {
	const CGRect viewBounds = self.bounds;
	log4Debug(@"Frame %@, scroller bounds %@, center %@, offset %f", NSStringFromCGRect(self.frame),
			  NSStringFromCGRect(viewBounds), NSStringFromCGPoint(self.center), self.contentOffset.x);
	const CGFloat width = pageCount * pageWidth;
	
	// determine number of pages to hold in memory
	const NSUInteger len = [self containerCountForViewWidth:viewBounds.size.width];
	NSUInteger idx = 0;
	
	if ( [pages count] > len ) {
		log4Debug(@"Discarding %d pages for reload", [pages count] - len);
		for ( idx = ([pages count] - len); idx > 0; idx-- ) {
			UIView *container = [pages lastObject];
			[container removeFromSuperview];
			[pages removeLastObject];
		}
	}
	[self recalculateScrollIndexesForNumberOfContainers:len];
	if ( !(BRFloatsAreEqual(self.contentSize.width, width)
		   && BRFloatsAreEqual(self.contentSize.height, viewBounds.size.height)) ) {
		self.contentSize = CGSizeMake(width, viewBounds.size.height);
		
		// in reverse mode, make sure if content width smaller than view width that content starts from right edge
		if ( reverseLayoutOrder && width < viewBounds.size.width ) {
			self.contentInset = UIEdgeInsetsMake(0, (viewBounds.size.width - width), 0, 0);
		} else {
			self.contentInset = UIEdgeInsetsZero;
		}
	}
	const CGRect pageFrame = CGRectMake(0, 0, pageWidth, viewBounds.size.height);
	for ( NSUInteger i = head, end = head + len, idx = 0; i < pageCount && i < end; i++, idx++ ) {
		CGFloat xOffset = (reverseLayoutOrder
						   ? (width - ((CGFloat)(i + 1) * pageWidth))
						   : (CGFloat)i * pageWidth);
		CGRect pageRect = CGRectMake(xOffset, 0.0, pageWidth, viewBounds.size.height);
		UIView *container;
		UIView *page;
		if ( idx < [pages count] ) {
			// reuse existing container
			container = [pages objectAtIndex:idx];
			container.bounds = pageFrame;
			container.center = CGPointMake(pageRect.origin.x + (pageRect.size.width / 2.0),
										   pageRect.origin.y + (pageRect.size.height / 2.0));
			page = [container.subviews objectAtIndex:0];
			if ( !CGRectEqualToRect(pageFrame, page.frame) ) {
				page.frame = pageFrame;
			}
		} else {
			// create new container
			log4Debug(@"Creating container %lu at %@", (unsigned long)i, NSStringFromCGRect(pageRect));
			container = [[UIView alloc] initWithFrame:pageRect];
			container.opaque = YES;
			page = [scrollerDelegate createReusablePageViewForScroller:self];
			if ( !CGRectEqualToRect(pageFrame, page.frame) ) {
				page.frame = pageFrame;
			}
			[container addSubview:page];
			[pages addObject:container];
			[self addSubview:container];
		}
		
		[scrollerDelegate scroller:self willDisplayPage:(i + infinitePageOffset) view:page];
	}
	if ( pageCount > 0 && [scrollerDelegate respondsToSelector:@selector(scroller:didDisplayPage:)] ) {
		[scrollerDelegate scroller:self didDisplayPage:centerIndex];
	}
	[self flashScrollIndicators];
}

- (void)layoutForCurrentScrollOffset {
	// calculate current "head" index
	NSUInteger currHead = [self calculateHeadForPageWidth:pageWidth numContainers:[pages count]];
	if ( currHead != head ) {
		[self layoutContainersForHead:currHead];
	}
	
	NSUInteger currCenter = [self calculateCenterForPageWidth:pageWidth numContainers:[pages count]];
	if ( currCenter != centerIndex && (infinite == YES || currCenter < pageCount) ) {
		if ( [scrollerDelegate respondsToSelector:@selector(scroller:willLeavePage:)] ) {
			[scrollerDelegate scroller:self willLeavePage:centerIndex];
		}
		centerIndex = currCenter;
	}
}

#pragma mark UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	if ( centeringReload || adjustingContent ) {
		return;
	}
	log4Trace(@"scrollView.contentSize.width = %f, scrollView.contentOffset.x = %f",
			  scrollView.contentSize.width, scrollView.contentOffset.x);
	scrolling = YES;
	if ( !BRFloatsAreEqual(lastScrollOffset, scrollView.contentOffset.x) ) {
		lastScrollDirection = scrollView.contentOffset.x < lastScrollOffset ? -1 : 1;
		lastScrollOffset = scrollView.contentOffset.x;
	}
	NSUInteger oldCenterExternal = centerIndex;
	[self layoutForCurrentScrollOffset];
	NSUInteger newCenterExternal = centerIndex;
	if ( oldCenterExternal != newCenterExternal && (infinite == YES || centerIndex < pageCount) ) {
		if ( [scrollerDelegate respondsToSelector:@selector(scroller:didLeavePage:)] ) {
			[scrollerDelegate scroller:self didLeavePage:oldCenterExternal];
		}
		if ( [scrollerDelegate respondsToSelector:@selector(scroller:didDisplayPage:)] ) {
			[scrollerDelegate scroller:self didDisplayPage:newCenterExternal];
		}
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	log4Trace(@"%@ did end deceleration, decelerating %d, dragging %d",
			  scrollView, scrollView.decelerating ? 1 : 0, scrollView.dragging ? 1 : 0);
	if ( [scrollerDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)] ) {
		[scrollerDelegate scrollViewDidEndDecelerating:scrollView];
	}
	[self handleDidSettle];
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	log4Trace(@"%@ did end scrolling animation, decelerating %d, dragging %d",
			  scrollView, scrollView.decelerating ? 1 : 0, scrollView.dragging ? 1 : 0);
	[self handleDidSettle];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	scrolling = YES;
	lastScrollOffset = scrollView.contentOffset.x;
	lastScrollDirection = 0;
	if ( [scrollerDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)] ) {
		[scrollerDelegate scrollViewWillBeginDragging:scrollView];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	log4Debug(@"Scroll view did end dragging, lastScrollOffset %ld, curr %ld; lastDir = %d",
			  (long)lastScrollOffset, (long)scrollView.contentOffset.x, lastScrollDirection);
	if ( [scrollerDelegate respondsToSelector:@selector(scrollerDidEndDragging:willDecelerate:pageDestination:)] ) {
		BRScrollerViewPageDestination destination = BRScrollerViewPageDestinationSame;
		if ( lastScrollDirection < 0 && centerIndex > 0) {
			destination = (reverseLayoutOrder
						   ? BRScrollerViewPageDestinationNext
						   : BRScrollerViewPageDestinationPrevious);
		} else if ( lastScrollDirection > 0 && centerIndex < pageCount ) {
			destination = (reverseLayoutOrder
						   ? BRScrollerViewPageDestinationPrevious
						   : BRScrollerViewPageDestinationNext);
		}
		[scrollerDelegate scrollerDidEndDragging:self willDecelerate:decelerate pageDestination:destination];
	}
	if ( [scrollerDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)] ) {
		[scrollerDelegate scrollViewDidEndDragging:self willDecelerate:decelerate];
	}
}

@end
