//
//  BRScrollerView.m
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRScrollerView.h"

#import "BRScrollerLogging.h"
#import "BRScrollerDelegate.h"
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
	BOOL infinite;
	
	BOOL ignoreScroll;
	BOOL scrolling;
	
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
	const BOOL animationsEnabled = [UIView areAnimationsEnabled];
	if ( animationsEnabled ) {
		[UIView setAnimationsEnabled:NO];
	}
	infinitePageOffset = [self calculateInfinitePageOffsetForCenterIndex:index];
	centerIndex = index;
	CGFloat xOffset = [self scrollOffsetForPageIndex:index];
	loaded = NO;
	ignoreScroll = YES;
	[self setContentOffset:CGPointMake(xOffset, 0) animated:NO];
	[self setNeedsLayout]; // force reload of pages, in case offset didn't actually change
	[self layoutIfNeeded];
	if ( pageCount > 0 && [scrollerDelegate respondsToSelector:@selector(scroller:didDisplayPage:)] ) {
		[scrollerDelegate scroller:self didDisplayPage:centerIndex];
	}
	ignoreScroll = NO;
	loaded = YES;
	if ( animationsEnabled ) {
		[UIView setAnimationsEnabled:YES];
	}
	[self flashScrollIndicators];
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
	return [self containerViewForIndex:viewIndex];
}

- (void)gotoPage:(const NSUInteger)index animated:(const BOOL)animated {
	const BOOL crossingInfiniteBounds = (infinite == NO ? NO : (index < infinitePageOffset || index > (infinitePageOffset + pageCount)));
	if ( crossingInfiniteBounds ) {
		// cannot animate easily because we cross infinite bounds :-(
		DDLogInfo(@"Crossing infinite boundary; animation disabled implicitly.");
		[self reloadDataCenteredOnPage:index];
		return;
	}
	CGFloat xOffset = [self scrollOffsetForPageIndex:index];
	if ( !BRFloatsAreEqual(xOffset, self.contentOffset.x) ) {
		const BOOL animationsEnabled = [UIView areAnimationsEnabled];
		if ( animationsEnabled && animated == NO ) {
			[UIView setAnimationsEnabled:NO];
		}
		[self setContentOffset:CGPointMake(xOffset, 0) animated:animated];
		if ( animationsEnabled && animated == NO  ) {
			[UIView setAnimationsEnabled:YES];
		}
		if ( animated == NO ) {
			// force layout to re-calculate centerIndex and process delegate messages
			[self layoutIfNeeded];
		}
	}
}

- (NSArray *)loadedReusablePages {
	return [pages copy];
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

- (void)setFrame:(CGRect)frame {
	const CGRect oldBounds = self.bounds;
	[super setFrame:frame];
	if ( (pageWidth > 0) == NO || CGSizeEqualToSize(oldBounds.size, frame.size) == NO ) {
		[self cachePageWidth];
		[self cachePageCount];
		[self setNeedsLayout];
	}
}

- (void)setBounds:(CGRect)bounds {
	const CGRect oldBounds = self.bounds;
	[super setBounds:bounds];
	if ( (pageWidth > 0) == NO || CGSizeEqualToSize(oldBounds.size, bounds.size) == NO ) {
		[self cachePageWidth];
		[self cachePageCount];
		[self setNeedsLayout];
	}
}

- (void)setContentOffset:(CGPoint)contentOffset {
	DDLogDebug(@"Adjusting contentOffset from %@ to %@", NSStringFromCGPoint(self.contentOffset), NSStringFromCGPoint(contentOffset));
	[super setContentOffset:contentOffset];
}

- (BOOL)adjustContentSize {
	const CGFloat height = self.bounds.size.height;
	const CGFloat width = pageCount * pageWidth;
	const CGSize expectedContentSize = CGSizeMake(width, height);
	if ( !CGSizeEqualToSize(self.contentSize, expectedContentSize) ) {
		ignoreScroll = YES;
		self.contentSize = expectedContentSize;
		ignoreScroll = NO;
		return YES;
	}
	return NO;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if ( !BRFloatsAreEqual(lastScrollOffset, self.contentOffset.x) ) {
		lastScrollDirection = self.contentOffset.x < lastScrollOffset ? -1 : 1;
		lastScrollOffset = self.contentOffset.x;
	}
	
	const NSUInteger oldCenterIndex = centerIndex;
	const BOOL resize = [self adjustContentSize];
	
	if ( resize ) {
		ignoreScroll = YES;
		CGFloat expectedOffset = [self scrollOffsetForPageIndex:oldCenterIndex];
		if ( BRFloatsAreEqual(self.contentOffset.x, expectedOffset) == NO ) {
			self.contentOffset = CGPointMake(expectedOffset, 0);
		}
	}
	
	if ( loaded == NO || [self containerCountForViewWidth:self.bounds.size.width] != [pages count] ) {
		[self setupContainersForPageWidth:(loaded == NO)];
	}
	
	[self layoutForCurrentScrollOffset];
	
	if ( resize ) {
		ignoreScroll = NO;
	}
	
	const NSUInteger newCenterIndex = centerIndex;
	if ( resize == NO && oldCenterIndex != newCenterIndex && (infinite == YES || newCenterIndex < pageCount) ) {
		if ( [scrollerDelegate respondsToSelector:@selector(scroller:didLeavePage:)] ) {
			[scrollerDelegate scroller:self didLeavePage:oldCenterIndex];
		}
		if ( [scrollerDelegate respondsToSelector:@selector(scroller:didDisplayPage:)] ) {
			[scrollerDelegate scroller:self didDisplayPage:newCenterIndex];
		}
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
			DDLogVerbose(@"Swapping page %lu and %lu", (unsigned long)i, (unsigned long)(i - shiftLen));
			[pages exchangeObjectAtIndex:i withObjectAtIndex:(i - shiftLen)];
		}
	} else if ( newHead < head && (head - newHead) < [pages count] ) {
		// scrolling left, shift
		NSUInteger shiftLen = head - newHead;
		reloadDataRange.length = shiftLen;
		for ( NSInteger i = ([pages count] - shiftLen - 1); i >= 0; i-- ) {
			DDLogVerbose(@"Swapping page %lu and %lu", (unsigned long)i, (unsigned long)(i+shiftLen));
			[pages exchangeObjectAtIndex:i withObjectAtIndex:(i+shiftLen)];
		}
	} else {
		// reload everything, no shifing
		reloadDataRange.length = [pages count];
	}
	const CGFloat pageHeight = self.bounds.size.height;
	for ( NSUInteger i = reloadDataRange.location; i < (reloadDataRange.location + reloadDataRange.length); i++ ) {
		UIView *page = [pages objectAtIndex:i];
		CGFloat xOffset = (reverseLayoutOrder
						   ? ((pageCount * pageWidth) - ((newHead + i + 1) * pageWidth))
						   : ((newHead + i) * pageWidth));
		DDLogVerbose(@"Moving container %lu (page %lu) from %@ to %@", (unsigned long)i, (unsigned long)(newHead + i + infinitePageOffset),
				  NSStringFromCGRect(page.frame), NSStringFromCGRect(CGRectMake(xOffset, 0, pageWidth, pageHeight)));
		CGPoint pageCenter = CGPointMake(xOffset + (pageWidth / 2.0), (pageHeight / 2.0));
		CGRect pageBounds = CGRectMake(0, 0, pageWidth, pageHeight);
		BOOL centerMoved = (CGPointEqualToPoint(pageCenter, page.center) == NO);
		if ( centerMoved ) {
			page.center = pageCenter;
		}
		if ( !CGRectEqualToRect(page.bounds, pageBounds) ) {
			page.bounds = pageBounds;
		}
		if ( ignoreScroll == NO ) {
			[scrollerDelegate scroller:self willDisplayPage:(newHead + i + infinitePageOffset) view:page];
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
	DDLogVerbose(@"offset %f, pageOffset = %f, pageCount = %lu, head = %lu, newHead = %lu", scrollOffset, pageOffset,
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
	DDLogVerbose(@"offset %f, pageCount = %lu, center = %lu, newCenter = %lu", self.contentOffset.x,
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
		const CGFloat oldScrollOffset = self.contentOffset.x;
		const CGFloat perfectOffsetDiff = oldScrollOffset - [self scrollOffsetForPageIndex:centerIndex];
		const NSUInteger oldHead = head;
		const BOOL reloadLeft = oldHead == 0;
		const BOOL reloadRight = oldHead == (pageCount - [pages count]);
		const BOOL animationsEnabled = [UIView areAnimationsEnabled];
		if ( animationsEnabled ) {
			[UIView setAnimationsEnabled:NO];
		}
		infinitePageOffset = newInfinitePageOffset;
		CGFloat xOffset = [self scrollOffsetForPageIndex:centerIndex] + perfectOffsetDiff;
		ignoreScroll = YES;
		[self setContentOffset:CGPointMake(xOffset, 0) animated:NO];
		ignoreScroll = NO;
		NSUInteger newHead = [self calculateHeadForPageWidth:pageWidth numContainers:[pages count]];
		if ( reloadLeft || reloadRight ) {
			// we've scrolled to the end of our current scroll bounds, so we need to shift the views over 1
			// so we don't reload views we've already configured. To do that, we trick
			// layoutContainersForHead: by setting head, so it shifts appropriately.
			head = newHead + (reloadLeft ? 1 : -1);
		} else {
			head = newHead;
		}
		[self layoutContainersForHead:newHead];
		[self setupContainersForPageWidth:NO];
		if ( animationsEnabled ) {
			[UIView setAnimationsEnabled:YES];
		}
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

- (void)setupContainersForPageWidth:(BOOL)reload {
	const CGRect viewBounds = self.bounds;
	DDLogDebug(@"Frame %@, scroller bounds %@, center %@, offset %f", NSStringFromCGRect(self.frame),
			  NSStringFromCGRect(viewBounds), NSStringFromCGPoint(self.center), self.contentOffset.x);
	const CGFloat width = pageCount * pageWidth;
	
	// determine number of pages to hold in memory
	const NSUInteger len = [self containerCountForViewWidth:viewBounds.size.width];
	NSUInteger idx = 0;
	
	const NSRange currContainerRange = NSMakeRange(head, [pages count]);
	[self recalculateScrollIndexesForNumberOfContainers:len];
	
	if ( currContainerRange.length > len ) {
		DDLogDebug(@"Discarding %lu pages for reload", (unsigned long)currContainerRange.length - len);
		for ( idx = (currContainerRange.length - len); idx > 0; idx-- ) {
			UIView *page = [pages lastObject];
			[page removeFromSuperview];
			[pages removeLastObject];
		}
	}
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
	const CGRect pageBounds = CGRectMake(0, 0, pageWidth, viewBounds.size.height);
	for ( NSUInteger i = head, end = head + len, idx = 0; i < pageCount && i < end; i++, idx++ ) {
		CGFloat xOffset = (reverseLayoutOrder
						   ? (width - ((CGFloat)(i + 1) * pageWidth))
						   : (CGFloat)i * pageWidth);
		CGPoint pageCenter = CGPointMake(xOffset + (pageWidth / 2.0), (pageBounds.size.height / 2.0));
		UIView *page;
		BOOL newPage = NO;
		if ( idx >= [pages count] ) {
			DDLogDebug(@"Creating page %lu", (unsigned long)i);
			page = [scrollerDelegate createReusablePageViewForScroller:self];
			[pages addObject:page];
			[self addSubview:page];
			newPage = YES;
		} else {
			page = pages[idx];
			newPage = ((currContainerRange.location + idx) != i);
		}
		if ( CGPointEqualToPoint(page.center, pageCenter) == NO ) {
			page.center = pageCenter;
		}
		if ( CGRectEqualToRect(page.bounds, pageBounds) == NO ) {
			page.bounds = pageBounds;
		}
		if ( reload || newPage ) {
			[scrollerDelegate scroller:self willDisplayPage:(i + infinitePageOffset) view:page];
		}
	}
}

- (void)layoutForCurrentScrollOffset {
	// calculate current "head" index
	NSUInteger currHead = [self calculateHeadForPageWidth:pageWidth numContainers:[pages count]];
	if ( currHead != head || ignoreScroll ) {
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
	if ( ignoreScroll ) {
		return;
	}
	DDLogVerbose(@"scrollView.contentSize.width = %f, scrollView.contentOffset.x = %f",
			  scrollView.contentSize.width, scrollView.contentOffset.x);
	scrolling = YES;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	DDLogVerbose(@"%@ did end deceleration, decelerating %d, dragging %d",
			  scrollView, scrollView.decelerating ? 1 : 0, scrollView.dragging ? 1 : 0);
	if ( [scrollerDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)] ) {
		[scrollerDelegate scrollViewDidEndDecelerating:scrollView];
	}
	[self handleDidSettle];
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
	DDLogVerbose(@"%@ did end scrolling animation, decelerating %d, dragging %d",
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
	DDLogDebug(@"Scroll view did end dragging, lastScrollOffset %ld, curr %ld; lastDir = %d",
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
