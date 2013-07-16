//
//  BRCenteringScrollView.m
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRCenteringScrollView.h"

@interface BRCenteringScrollView () <UIScrollViewDelegate>
@end

@implementation BRCenteringScrollView {
	__weak id<BRScrollViewDelegate> scrollDelegate;
}

@synthesize scrollDelegate;

- (id)initWithFrame:(CGRect)theFrame {
	if ( (self = [super initWithFrame:theFrame]) ) {
		self.minimumZoomScale = 1.0;
		self.maximumZoomScale = 8.0;
		self.scrollEnabled = YES;
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

#pragma mark Layout

- (void)setFrame:(CGRect)frame {
	// UIScrollView will automatically choose a new contentOffset value when the frame changes,
	// but this can lead to the wrong desired offset in the case of rotation, where we will
	// be changing the contentSize to adjust to the new frame size. What we want is for the
	// visual center of the managed content area (our own view bounds) to remain unchanged, so
	// the content appears to rotate about the center point.
	//
	// So we calculate that visual center before the frame changes, then re-calculate it
	// after setting the frame to achieve the desired effect.

	const CGSize oldViewSize = self.bounds.size;
	const CGPoint oldContentOffset = self.contentOffset;
	const CGSize oldContentSize = self.contentSize;
	const CGPoint centerCoordinate = CGPointMake((oldContentOffset.x + oldViewSize.width * 0.5) / oldContentSize.width,
												(oldContentOffset.y + oldViewSize.height * 0.5) / oldContentSize.height);
	[super setFrame:frame];
	if ( oldContentOffset.y > 0 ) {
		[self layoutIfNeeded]; // calling this might adjust the contentSize to fit new view bounds
		const CGSize newContentSize = self.contentSize;
		const CGPoint newCenterPoint = CGPointMake(centerCoordinate.x * newContentSize.width, centerCoordinate.y * newContentSize.height);
		const CGPoint newOffset = CGPointMake(newCenterPoint.x - frame.size.width * 0.5, newCenterPoint.y - frame.size.height * 0.5);
		[self setContentOffset:newOffset animated:NO];
	}
}

- (void)setContentOffset:(const CGPoint)offset {
	// When the contentSize is smaller than our view bounds, the following keeps the content centered. Normally
	// UIScrollView will position the view in the top-left corner. This logic is done here because it applies
	// also during zooming operations, where UIScrollView adjusts the contentOffset and contentSize.
	
	CGPoint newOffset = offset;
	UIView *managedView = [self viewForZoomingInScrollView:self];
	if ( managedView != nil ) {
		CGSize contentSize = self.contentSize;
		UIEdgeInsets inset = self.contentInset;
		contentSize.width += inset.left + inset.right;
		contentSize.height += inset.top + inset.bottom;
		CGSize viewSize = self.bounds.size;
		if ( contentSize.width < viewSize.width ) {
			newOffset.x = -(viewSize.width - contentSize.width) / 2.0;
		}
		if ( contentSize.height < viewSize.height ) {
			newOffset.y = -(viewSize.height - contentSize.height) / 2.0;
		}
		log4Trace(@"Centered offset %@ for size %@", NSStringFromCGPoint(newOffset), NSStringFromCGSize(contentSize));
	}
	log4Trace(@"Changing contentOffset (requested %@) from %@ to %@", NSStringFromCGPoint(offset),
			  NSStringFromCGPoint(self.contentOffset), NSStringFromCGPoint(newOffset));
	[super setContentOffset:newOffset];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	// This method is called after view bounds changes as well as during scrolling/zooming gestures. That means
	// we need to let the managed view relayout as well, so it can display pages correctly. We also have to check
	// if the contentSize needs adjusting to fit our current view bounds.
	
	UIView *managedView = [self viewForZoomingInScrollView:self];
	if ( !self.zooming ) {
		log4Trace(@"Layout size %@; center = %@", NSStringFromCGSize(managedView.bounds.size), NSStringFromCGPoint(managedView.center));
		
		// Here we check for size adjustment of our bounds, and adjust managed size accordingly. Adjusting the view size
		// means we also adjust our own contentSize to match. Changing contentSize causes UIScrollView's contentOffset
		// to then not match the relative offset we were in at the old size, so we re-compute a new contentOffset
		// based on the change in scale of the contentSize.
		
		CGSize viewSize = self.bounds.size;
		CGSize size = [managedView sizeThatFits:viewSize];
		CGAffineTransform contentScale = CGAffineTransformMakeScale(self.zoomScale, self.zoomScale);
		CGSize contentSize = CGSizeApplyAffineTransform(size, contentScale);
		if ( !CGSizeEqualToSize(contentSize, self.contentSize) ) {
			CGFloat diffScale = size.width / managedView.bounds.size.width;
			CGPoint contentOffset = self.contentOffset;
			contentOffset = CGPointApplyAffineTransform(contentOffset, CGAffineTransformMakeScale(diffScale, diffScale));
			
			// if contentOffset values < 0, we have adjusted them to be centered... but need to keep this centered at new size now
			if ( contentOffset.x < 0 ) {
				contentOffset.x = MAX(0.0, -(viewSize.width - contentSize.width) / 2.0);
			}
			if ( contentOffset.y < 0 ) {
				contentOffset.y = MAX(0.0, -(viewSize.height - contentSize.height) / 2.0);
			}
			managedView.bounds = CGRectMake(0, 0, size.width, size.height);
			managedView.center = CGPointApplyAffineTransform(CGPointMake(size.width / 2.0, size.height / 2.0), contentScale);
			self.contentSize = contentSize;
			[self setContentOffset:contentOffset animated:NO];
		/*} else {
			// during scrolling, re-layout managed content
			[managedView setNeedsLayout];*/
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

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale {
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
