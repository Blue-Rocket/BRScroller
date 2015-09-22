//
//  BRCenteringScrollView.m
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRCenteringScrollView.h"

#import "BRScrollerLogging.h"

@interface BRCenteringScrollView () <UIGestureRecognizerDelegate>
@end

@implementation BRCenteringScrollView {
	__weak id<BRScrollViewDelegate> scrollDelegate;
	UITapGestureRecognizer *doubleTapRecognizer;
	CGFloat doubleTapZoomIncrement;
	CGFloat doubleTapMaxZoomLevel;
	CGSize managedViewSize;
}

@synthesize scrollDelegate;
@synthesize doubleTapZoomIncrement, doubleTapMaxZoomLevel, doubleTapRecognizer;

- (id)initWithFrame:(CGRect)theFrame {
	if ( (self = [super initWithFrame:theFrame]) ) {
		self.minimumZoomScale = 1.0;
		self.maximumZoomScale = 8.0;
		self.scrollEnabled = YES;
		doubleTapZoomIncrement = 2;
		doubleTapMaxZoomLevel = 8;
		[super setDelegate:self];
	}
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	if ( (self = [super initWithCoder:aDecoder]) ) {
		[super setDelegate:self];
	}
	return self;
}

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate {
	if ( delegate != nil ) {
		NSAssert(NO, @"You may not set a scroll view delegate on a %@", NSStringFromClass([self class]));
	}
}

- (void)setDoubleTapToZoom:(BOOL)value {
	if ( value == NO ) {
		if ( doubleTapRecognizer != nil ) {
			[self removeGestureRecognizer:doubleTapRecognizer];
			doubleTapRecognizer = nil;
		}
	} else {
		doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapZoom:)];
		doubleTapRecognizer.numberOfTapsRequired = 2;
		doubleTapRecognizer.delegate = self;
		[self addGestureRecognizer:doubleTapRecognizer];
	}
}

- (void)doubleTapZoom:(UITapGestureRecognizer *)recognizer {
	const CGPoint contentOffset = self.contentOffset;
	UIView *managedView = [self viewForZoomingInScrollView:self];
	CGPoint boundsPoint = [recognizer locationInView:self];
	boundsPoint.x -= contentOffset.x;
	boundsPoint.y -= contentOffset.y;
	CGPoint contentPoint = [recognizer locationInView:managedView];
	if ( self.zoomScale < doubleTapMaxZoomLevel ) {
		const CGFloat destZoomScale = floorf((self.zoomScale * doubleTapZoomIncrement) / doubleTapZoomIncrement) * doubleTapZoomIncrement;
		// zoom to 2x
		CGSize bounds = self.bounds.size;
		CGSize zoomBounds = bounds;
		zoomBounds.width /= destZoomScale;
		zoomBounds.height /= destZoomScale;
		CGFloat xPercent = boundsPoint.x / bounds.width;
		CGFloat yPercent = boundsPoint.y / bounds.height;
		CGRect zoomToRect = CGRectMake(contentPoint.x - (zoomBounds.width * xPercent),
									   contentPoint.y - (zoomBounds.height * yPercent),
									   zoomBounds.width, zoomBounds.height);
		DDLogDebug(@"Zoom scale %f %@ from %@ to %@",
				  self.zoomScale, NSStringFromCGPoint(self.contentOffset),
				  NSStringFromCGRect(CGRectMake(self.contentOffset.x, self.contentOffset.y, self.bounds.size.width, self.bounds.size.height)),
				  NSStringFromCGRect(zoomToRect));
		[self zoomToRect:zoomToRect animated:YES];
	} else {
		[self setZoomScale:1.0 animated:YES];
	}
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	// only detect double taps on the managed view itself, not in any borders outside the view bounds
	UIView *managedView = [self viewForZoomingInScrollView:self];
	return (managedView == nil
			? NO
			: CGRectContainsPoint(managedView.bounds, [touch locationInView:managedView]));
}

#pragma mark Layout

- (void)setBounds:(CGRect)bounds {
	// UIScrollView will automatically choose a new contentOffset value when the frame changes,
	// but this can lead to the wrong desired offset in the case of rotation, where we will
	// be changing the contentSize to adjust to the new frame size. What we want is for the
	// visual center of the managed content area (our own view bounds) to remain unchanged, so
	// the content appears to rotate about the center point.
	//
	// So we calculate that visual center before the frame changes, then re-calculate it
	// after setting the frame to achieve the desired effect.
	
	DDLogDebug(@"Will set bounds from %@ to %@", NSStringFromCGRect(self.bounds), NSStringFromCGRect(bounds));
	
	const CGSize oldViewSize = self.bounds.size;
	const CGPoint oldContentOffset = self.contentOffset;
	const CGSize oldContentSize = self.contentSize;
	const BOOL resize = ((oldContentSize.width > 0.0 && oldContentSize.height > 0.0) == NO
						 || (oldContentSize.width > 0.0 && oldContentSize.height > 0.0 && CGSizeEqualToSize(oldViewSize, bounds.size) == NO));
	CGPoint newOffset = CGPointZero;
	UIView *managedView = [self viewForZoomingInScrollView:self];
	if ( resize ) {
		CGSize viewSize = bounds.size;
		CGAffineTransform contentScale = CGAffineTransformMakeScale(self.zoomScale, self.zoomScale);
		[self cacheManagedViewSize:managedView forViewSize:viewSize];
		CGSize newContentSize = CGSizeApplyAffineTransform(managedViewSize, contentScale);
		CGPoint centerCoordinate;
		if ( oldContentSize.width > 0 && oldContentSize.height > 0 ) {
			centerCoordinate = CGPointMake((oldContentOffset.x + oldViewSize.width * 0.5) / oldContentSize.width,
										   (oldContentOffset.y + oldViewSize.height * 0.5) / oldContentSize.height);
		} else {
			centerCoordinate = CGPointMake(0.5, 0.5);
		}
		if ( CGPointEqualToPoint(oldContentOffset, CGPointZero) == NO ) {
			newOffset = CGPointMake(MAX(0.0, centerCoordinate.x * newContentSize.width - bounds.size.width * 0.5),
									MAX(0.0, centerCoordinate.y * newContentSize.height - bounds.size.height * 0.5));
		}
		newOffset = [self centeredOffsetForRequestedOffset:newOffset contentSize:newContentSize viewSize:viewSize];
		[UIView setAnimationsEnabled:NO];
		self.contentSize = newContentSize;
		[UIView setAnimationsEnabled:YES];
	} else {
		newOffset = [self centeredOffsetForRequestedOffset:bounds.origin contentSize:oldContentSize viewSize:oldViewSize];
	}
	bounds.origin.x = newOffset.x;
	bounds.origin.y = newOffset.y;
	[super setBounds:bounds];
	DDLogDebug(@"Did set bounds from %@ to %@", NSStringFromCGRect(self.bounds), NSStringFromCGRect(bounds));
}

- (void)cacheManagedViewSize:(UIView *)managedView forViewSize:(CGSize)viewSize {
	managedViewSize = [managedView sizeThatFits:viewSize];
}

- (CGPoint)centeredOffsetForRequestedOffset:(CGPoint)offset contentSize:(CGSize)contentSize viewSize:(CGSize)viewSize {
	CGPoint newOffset = offset;
	UIView *managedView = [self viewForZoomingInScrollView:self];
	if ( managedView != nil && CGSizeEqualToSize(CGSizeZero, self.contentSize) == NO ) {
		UIEdgeInsets inset = self.contentInset;
		contentSize.width += inset.left + inset.right;
		contentSize.height += inset.top + inset.bottom;
		if ( contentSize.width < viewSize.width ) {
			newOffset.x = -(viewSize.width - contentSize.width) / 2.0;
		}
		if ( contentSize.height < viewSize.height ) {
			newOffset.y = -(viewSize.height - contentSize.height) / 2.0;
		}
		DDLogVerbose(@"Centered offset %@ for size %@", NSStringFromCGPoint(newOffset), NSStringFromCGSize(contentSize));
	}
	return newOffset;
}

- (void)setContentOffset:(const CGPoint)offset {
	// When the contentSize is smaller than our view bounds, the following keeps the content centered. Normally
	// UIScrollView will position the view in the top-left corner. This logic is done here because it applies
	// also during zooming operations, where UIScrollView adjusts the contentOffset and contentSize.
	
	CGPoint newOffset = [self centeredOffsetForRequestedOffset:offset contentSize:self.contentSize viewSize:self.bounds.size];
	DDLogVerbose(@"Changing contentOffset (requested %@) from %@ to %@", NSStringFromCGPoint(offset),
			  NSStringFromCGPoint(self.contentOffset), NSStringFromCGPoint(newOffset));
	[super setContentOffset:newOffset];
}

- (void)didAddSubview:(UIView *)subview {
	UIView *managedView = [self viewForZoomingInScrollView:self];
	if ( subview == managedView ) {
		[self cacheManagedViewSize:managedView forViewSize:self.bounds.size];
	}
}

- (void)layoutSubviews {
	[super layoutSubviews];
	UIView *managedView = [self viewForZoomingInScrollView:self];
	[self cacheManagedViewSize:managedView forViewSize:self.bounds.size];
	if ( managedView ) {
		CGRect expectedBounds = CGRectMake(0, 0, managedViewSize.width, managedViewSize.height);
		if ( CGRectEqualToRect(expectedBounds, managedView.bounds) == NO ) {
			[UIView setAnimationsEnabled:NO];
			managedView.bounds = expectedBounds;
			[UIView setAnimationsEnabled:YES];
		}
		CGSize contentSize = self.contentSize;
		CGPoint expectedCenter = CGPointMake(contentSize.width * 0.5, contentSize.height * 0.5);
		if ( CGPointEqualToPoint(expectedCenter, managedView.center) == NO ) {
			[UIView setAnimationsEnabled:NO];
			managedView.center = expectedCenter;
			[UIView setAnimationsEnabled:YES];
		}
	}
}

#pragma UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	if ( [scrollDelegate respondsToSelector:@selector(viewForZoomingInScrollView:)] ) {
		return [scrollDelegate viewForZoomingInScrollView:self];
	}
	return nil;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
	if ( [scrollDelegate respondsToSelector:@selector(scrollViewWillBeginZooming:withView:)] ) {
		[scrollDelegate scrollViewWillBeginZooming:self withView:view];
	}
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
	if ( [scrollDelegate respondsToSelector:@selector(scrollViewDidZoom:)] ) {
		[scrollDelegate scrollViewDidZoom:self];
	}
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
	if ( [scrollDelegate respondsToSelector:@selector(scrollViewDidEndZooming:withView:atScale:)] ) {
		[scrollDelegate scrollViewDidEndZooming:self withView:view atScale:scale];
	}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if ( [scrollDelegate respondsToSelector:@selector(scrollViewWillBeginDragging:)] ) {
		[scrollDelegate scrollViewWillBeginDragging:self];
	}
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if ( [scrollDelegate respondsToSelector:@selector(scrollViewDidEndDragging:willDecelerate:)] ) {
		[scrollDelegate scrollViewDidEndDragging:self willDecelerate:decelerate];
	}
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	if ( [scrollDelegate respondsToSelector:@selector(scrollViewDidEndDecelerating:)] ) {
		[scrollDelegate scrollViewDidEndDecelerating:self];
	}
}

@end
