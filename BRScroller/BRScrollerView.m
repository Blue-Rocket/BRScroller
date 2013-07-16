//
//  BRScrollerView.m
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRScrollerView.h"

#import "BRScrollerDelegate.h"
#import "BRScrollerUtilities.h"

@interface BRScrollerView () <UIScrollViewDelegate>
@end

@implementation BRScrollerView {
	__weak id<BRScrollerDelegate> scrollerDelegate;
	BOOL loaded;
	BOOL reverseLayoutOrder;
	BOOL centeringReload;
	BOOL scrolling;
	BOOL adjustingContent;
	
	int lastScrollDirection;
	CGFloat lastScrollOffset;
	NSUInteger head;
	NSUInteger centerIndex;
	NSMutableArray *pages;
}

@synthesize scrollerDelegate, loaded, reverseLayoutOrder;

- (id)initWithFrame:(CGRect)frame {
	if ( (self = [super initWithFrame:frame]) ) {
		[self initializeBRScrollerViewDefaults];
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		self.scrollEnabled = YES;
		self.userInteractionEnabled = YES;
		self.multipleTouchEnabled = YES;
		self.opaque = NO;
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
	pages = [[NSMutableArray alloc] init];
}

#pragma mark - Accessors

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate {
	if ( delegate != nil ) {
		NSAssert(NO, @"You may not set a scroll view delegate on a %@", NSStringFromClass([self class]));
	}
}

#pragma mark Public API

- (void)reloadDataCenteredOnPage:(NSUInteger)index {
	// disable implicit animation here, so we avoid a "stretching" effect
	[CATransaction begin]; {
		[CATransaction setDisableActions:YES];
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

- (void) reloadData {
	[self reloadDataCenteredOnPage:0];
}

- (void)releaseAllReusablePages {
	[self releaseAllContainers];
}

- (UIView *)reusablePageViewForCenterPage {
	return [self reusablePageViewAtIndex:centerIndex];
}

- (UIView *)reusablePageViewAtIndex:(NSUInteger)viewIndex {
	UIView *container = [self containerViewForIndex:viewIndex];
	NSArray *sv = [container subviews];
	return ([sv count] < 1 ? nil : [sv objectAtIndex:0]);
}

- (void)gotoPage:(NSUInteger)index animated:(BOOL)animated {
    CGFloat xOffset = [self scrollOffsetForPageIndex:index];
	if ( !BRFloatsAreEqual(xOffset, self.contentOffset.x) ) {
		if ( !animated ) {
			centeringReload = YES;
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
		}
		[self setContentOffset:CGPointMake(xOffset, 0) animated:animated];
		if ( !animated ) {
			scrolling = NO;
			centeringReload = NO;
			[self layoutForScrollView:self];
			[CATransaction commit];
			if ( centerIndex < [scrollerDelegate numberOfPagesInScroller:self]
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
	return NSMakeRange(head, pages.count);
}

- (NSUInteger)centerPageIndex {
	return centerIndex;
}

- (void)gotoNextPage {
	NSUInteger currPage = [self centerPageIndex];
	NSUInteger numPages = [scrollerDelegate numberOfPagesInScroller:self];
	if ( currPage + 1 < numPages) {
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
	NSUInteger currIndex = [self centerPageIndex];
	[super setFrame:frame];
	if ( loaded ) {
		// automatically go back to former page index
		[self gotoPage:currIndex animated:NO];
		[self setNeedsLayout];
	}
}

- (void)setBounds:(CGRect)bounds {
	NSUInteger currIndex = [self centerPageIndex];
	CGRect oldBounds = self.bounds;
	[super setBounds:bounds];
	if ( loaded && !BRFloatsAreEqual(bounds.size.width, oldBounds.size.width) ) {
		// automatically go back to former page index
		[self gotoPage:currIndex animated:NO];
		[self setNeedsLayout];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// During rotation, here is where we'll re-layout our pages for the new dimensions of the scroll 
	// We do this by checking if the contentSize differs from what we calculate *should* be the contentSize
	// based on the current view bounds... if it doesn't match the epxected size, we re-lay out the pages.
	
	CGFloat height = self.bounds.size.height;
	CGFloat pageWidth = self.bounds.size.width;
	if ( [scrollerDelegate respondsToSelector:@selector(uniformPageWidthForScroller:)] ) {
		pageWidth = [scrollerDelegate uniformPageWidthForScroller:self];
	} // TODO: implement individual page length layout
	
	NSUInteger numPages = [scrollerDelegate numberOfPagesInScroller:self];
	CGFloat width = numPages * pageWidth;
	
	if ( !BRFloatsAreEqual(self.contentSize.height, height) || !BRFloatsAreEqual(width, self.contentSize.width) ) {
		CGSize newSize = CGSizeMake(width, height);
		adjustingContent = YES;
		log4Debug(@"Adjusting content size from %@ to %@", NSStringFromCGSize(self.contentSize), NSStringFromCGSize(newSize));
		self.contentSize = newSize;
		adjustingContent = NO;
		log4Debug(@"Laying out scroller pages at %dx%d", (int)pageWidth, (int)height);
		for ( NSUInteger idx = 0, i = head, end = pages.count; idx < end; i++, idx++ ) {
			CGFloat xOffset = [self scrollOffsetForPageIndex:i pageWidth:pageWidth pageCount:numPages];
			CGRect pageRect = CGRectMake(xOffset, 0.0, pageWidth, height);
			UIView *container = [pages objectAtIndex:idx];
			container.bounds = CGRectMake(0, 0, pageRect.size.width, pageRect.size.height);
			container.center = CGPointMake(pageRect.origin.x + (pageRect.size.width / 2.0),
										   pageRect.origin.y + (pageRect.size.height / 2.0));
			UIView *page = [container.subviews objectAtIndex:0];
			if ( !CGSizeEqualToSize(page.bounds.size, pageRect.size) ) {
				page.frame = CGRectMake(0, 0, pageRect.size.width, pageRect.size.height);
			}
		}
	}
}

- (CGFloat)scrollOffsetForPageIndex:(NSUInteger)index {
    CGFloat pageWidth = 0;
	if ( [scrollerDelegate respondsToSelector:@selector(uniformPageWidthForScroller:)] ) {
		pageWidth = [scrollerDelegate uniformPageWidthForScroller:self];
	} else {
		pageWidth = self.bounds.size.width;
	} // TODO: implement individual page length layout
	return [self scrollOffsetForPageIndex:index pageWidth:pageWidth pageCount:[scrollerDelegate numberOfPagesInScroller:self]];
}

- (CGFloat)scrollOffsetForPageIndex:(NSUInteger)index pageWidth:(CGFloat)pageWidth pageCount:(NSUInteger)pageCount {
	if ( index >= pageCount ) {
		index = 0; // force to page 1
	}
	CGFloat width = pageCount * pageWidth;
	return (reverseLayoutOrder
			? (width - ((CGFloat)(index + 1) * pageWidth))
			: (CGFloat)index * pageWidth);
}

- (void)releaseAllContainers {
	[pages makeObjectsPerformSelector:@selector(removeFromSuperview)];
	[pages removeAllObjects];
}

- (UIView *)containerViewForIndex:(NSUInteger)index {
	if ( index < head || (head + pages.count) <= index ) {
		// page not currently loaded
		return nil;
	}
	UIView *container = [pages objectAtIndex:(index - head)];
	return container;
}

- (void)layoutContainersForHead:(NSUInteger)newHead {
	// check if we can shift any curent containers
	NSRange reloadDataRange = NSMakeRange(0, 0);
	if ( newHead > head && newHead < (head + pages.count)  ) {
		// scrolling right, shift
		NSUInteger shiftLen = newHead - head;
		reloadDataRange.location = pages.count - shiftLen;
		reloadDataRange.length = shiftLen;
		for ( NSUInteger i = shiftLen; i < pages.count; i++ ) {
			log4Trace(@"Swapping page %lu and %lu", (unsigned long)i, (unsigned long)(i - shiftLen));
			[pages exchangeObjectAtIndex:i withObjectAtIndex:(i - shiftLen)];
		}
	} else if ( newHead < head && (head - newHead) < pages.count ) {
		// scrolling left, shift
		NSUInteger shiftLen = head - newHead;
		reloadDataRange.length = shiftLen;
		for ( NSInteger i = (pages.count - shiftLen - 1); i >= 0; i-- ) {
			log4Trace(@"Swapping page %lu and %lu", (unsigned long)i, (unsigned long)(i+shiftLen));
			[pages exchangeObjectAtIndex:i withObjectAtIndex:(i+shiftLen)];
		}
	} else {
		// reload everything, no shifing
		reloadDataRange.length = pages.count;
	}
	
	CGFloat pageLength = 0;
	if ( [scrollerDelegate respondsToSelector:@selector(uniformPageWidthForScroller:)] ) {
		pageLength = [scrollerDelegate uniformPageWidthForScroller:self];
	}
	
	for ( NSUInteger i = reloadDataRange.location; i < (reloadDataRange.location + reloadDataRange.length); i++ ) {
		UIView *container = (UIView *)[pages objectAtIndex:i];
		CGFloat xOffset = (reverseLayoutOrder
						   ? (self.contentSize.width - ((newHead + i + 1) * pageLength))
						   : ((newHead + i) * pageLength));
		CGRect newFrame = CGRectMake(xOffset, 0, pageLength, self.bounds.size.height);
		log4Trace(@"Moving container %lu (page %lu) from %@ to %@", (unsigned long)i, (unsigned long)(newHead + i),
				  NSStringFromCGRect(container.frame), NSStringFromCGRect(newFrame));
		container.frame = newFrame;
		[scrollerDelegate scroller:self willDisplayPage:(newHead + i) view:[container.subviews objectAtIndex:0]];
	}
	
	head = newHead;
}

- (NSUInteger)calculateHeadForPageWidth:(CGFloat)pageWidth numPages:(NSUInteger)pageCount {
	// we change head pointer when scrolling past half-way width of pages, so swapping them around
	// does not affect visible pages
	CGFloat scrollOffset = (reverseLayoutOrder
							? self.contentSize.width - self.contentOffset.x - self.bounds.size.width
							: self.contentOffset.x);
	CGFloat pageOffset = (scrollOffset - (pageWidth / 2.0)) / pageWidth;
	NSUInteger h = MIN([scrollerDelegate numberOfPagesInScroller:self] - pageCount,
					   MAX(0, floorf(pageOffset)));
	log4Trace(@"offset %f, pageOffset = %f, pageCount = %lu, head = %lu, newHead = %lu", scrollOffset, pageOffset,
			  (unsigned long)pageCount, (unsigned long)head, (unsigned long)h);
	return h;
}

- (NSUInteger)calculateCenterForPageWidth:(CGFloat)pageWidth
								  numPages:(NSUInteger)pageCount {
	// calculate "center" visible page, and report that. this really designed
	// for "paging" mode, where pages are full width of this view's bounds
	CGFloat xOffset = (reverseLayoutOrder
					   ? (self.contentSize.width - self.contentOffset.x - (self.bounds.size.width / 2.0))
					   : (self.contentOffset.x + (self.bounds.size.width / 2.0)));
	NSUInteger c = MIN([scrollerDelegate numberOfPagesInScroller:self],
					   MAX(0, floorf(xOffset / pageWidth)));
	log4Trace(@"offset %f, pageCount = %lu, center = %lu, newCenter = %lu", self.contentOffset.x,
			  (unsigned long)pageCount, (unsigned long)centerIndex, (unsigned long)c);
	return c;
}

- (void)recalculateScrollIndexesForNumberOfPages:(NSUInteger)pageCount {
	CGFloat pageLength = 0;
	if ( [scrollerDelegate respondsToSelector:@selector(uniformPageWidthForScroller:)] ) {
		pageLength = [scrollerDelegate uniformPageWidthForScroller:self];
	}
	
	head = [self calculateHeadForPageWidth:pageLength numPages:pageCount];
	
	centerIndex = [self calculateCenterForPageWidth:pageLength
										   numPages:pageCount];
}

- (void)handleDidSettle {
	scrolling = NO;
	if ( self.pagingEnabled && [scrollerDelegate respondsToSelector:@selector(scroller:didSettleOnPage:)] ) {
		CGFloat pageLength = 0;
		if ( [scrollerDelegate respondsToSelector:@selector(uniformPageWidthForScroller:)] ) {
			pageLength = [scrollerDelegate uniformPageWidthForScroller:self];
		}
		NSUInteger currCenter = [self calculateCenterForPageWidth:pageLength
														 numPages:pages.count];
		[scrollerDelegate scroller:self didSettleOnPage:currCenter];
	}
}

- (void)reloadDataInternal {
	log4Debug(@"Frame %@, scroller bounds %@, center %@, offset %f", NSStringFromCGRect(self.frame),
			  NSStringFromCGRect(self.bounds), NSStringFromCGPoint(self.center), self.contentOffset.x);
	NSUInteger numPages = [scrollerDelegate numberOfPagesInScroller:self];
	CGFloat pageWidth = 0;
	if ( [scrollerDelegate respondsToSelector:@selector(uniformPageWidthForScroller:)] ) {
		pageWidth = [scrollerDelegate uniformPageWidthForScroller:self];
	} // TODO: implement individual page length layout
	CGFloat width = numPages * pageWidth;
	CGSize currSize = self.bounds.size;
	
	// determine number of pages to hold in memory (viewable + 2 for extra left and right)
	NSUInteger len = MIN(numPages, (NSUInteger)ceilf(currSize.width / pageWidth) + 2);
	NSUInteger idx = 0;
	BOOL reverse = reverseLayoutOrder;
	
	if ( pages.count > len ) {
		log4Debug(@"Discarding %d pages for reload", pages.count - len);
		for ( idx = (pages.count - len); idx > 0; idx-- ) {
			UIView *container = [pages lastObject];
			[container removeFromSuperview];
			[pages removeLastObject];
		}
	}
	[self recalculateScrollIndexesForNumberOfPages:len];
	if ( !(BRFloatsAreEqual(self.contentSize.width, width)
		   && BRFloatsAreEqual(self.contentSize.height, currSize.height)) ) {
		self.contentSize = CGSizeMake(width, currSize.height);
		
		// in reverse mode, make sure if content width smaller than view width that content starts from right edge
		if ( reverse && width < currSize.width ) {
			self.contentInset = UIEdgeInsetsMake(0, (currSize.width - width), 0, 0);
		} else {
			self.contentInset = UIEdgeInsetsZero;
		}
	}
	for ( NSUInteger i = head, end = head + len, idx = 0; i < numPages && i < end; i++, idx++ ) {
		CGFloat xOffset = (reverse
						   ? (width - ((CGFloat)(i + 1) * pageWidth))
						   : (CGFloat)i * pageWidth);
		CGRect pageRect = CGRectMake(xOffset, 0.0, pageWidth, self.bounds.size.height);
		UIView *container;
		UIView *page;
		if ( idx < pages.count ) {
			// reuse existing container
			container = [pages objectAtIndex:idx];
			container.bounds = CGRectMake(0, 0, pageRect.size.width, pageRect.size.height);
			container.center = CGPointMake(pageRect.origin.x + (pageRect.size.width / 2.0),
										   pageRect.origin.y + (pageRect.size.height / 2.0));
			page = [container.subviews objectAtIndex:0];
			page.frame = CGRectMake(0, 0, pageRect.size.width, pageRect.size.height);
		} else {
			// create new container
			log4Debug(@"Creating container %lu at %@", (unsigned long)i, NSStringFromCGRect(pageRect));
			container = [[UIView alloc] initWithFrame:pageRect];
			container.opaque = YES;
			page = [scrollerDelegate createReusablePageViewForScroller:self];
			page.frame = CGRectMake(0, 0, pageRect.size.width, pageRect.size.height);
			[container addSubview:page];
			[pages addObject:container];
			[self addSubview:container];
		}
		
		[scrollerDelegate scroller:self willDisplayPage:i view:page];
	}
	if ( [scrollerDelegate respondsToSelector:@selector(scroller:didDisplayPage:)] ) {
		[scrollerDelegate scroller:self didDisplayPage:centerIndex];
	}
	[self flashScrollIndicators];
}

- (void)layoutForScrollView:(UIScrollView *)scrollView {
	CGFloat pageLength = 0;
	if ( [scrollerDelegate respondsToSelector:@selector(uniformPageWidthForScroller:)] ) {
		pageLength = [scrollerDelegate uniformPageWidthForScroller:self];
	}
	
	// calculate current "head" index
	NSUInteger currHead = [self calculateHeadForPageWidth:pageLength numPages:pages.count];
	if ( currHead != head ) {
		[self layoutContainersForHead:currHead];
	}
	
	NSUInteger currCenter = [self calculateCenterForPageWidth:pageLength
													 numPages:pages.count];
	if ( currCenter != centerIndex && currCenter < [scrollerDelegate numberOfPagesInScroller:self] ) {
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
	NSUInteger oldCenter = centerIndex;
	[self layoutForScrollView:scrollView];
	if ( oldCenter != centerIndex && centerIndex < [scrollerDelegate numberOfPagesInScroller:self] ) {
		if ( [scrollerDelegate respondsToSelector:@selector(scroller:didLeavePage:)] ) {
			[scrollerDelegate scroller:self didLeavePage:oldCenter];
		}
		if ( [scrollerDelegate respondsToSelector:@selector(scroller:didDisplayPage:)] ) {
			[scrollerDelegate scroller:self didDisplayPage:centerIndex];
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
		} else if ( lastScrollDirection > 0 && centerIndex < [scrollerDelegate numberOfPagesInScroller:self] ) {
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
