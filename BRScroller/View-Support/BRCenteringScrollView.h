//
//  BRCenteringScrollView.h
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

#import "BRScrollViewDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A @c UIScrollView designed to manage zoomable content. It keeps the content
 centered, and keeps track of view size changes, keeping tne content in view
 when possible, such as when the interface orientation changes.
 
 This view is its own @c UIScrollViewDelegate. Setting the delegate property
 to some other instance will not work. The managed content view is the one
 returned by @c viewForZoomingInScrollView:, so subclasses should implement
 that method and return the appropriate view, or the @c scrollDelegate should.
 In addition, the managed content view's @c sizeThatFits: method will be used 
 to determine this view's @c contentSize value. Thus the managed view should 
 implement that method in such a way that it returns the view's @i natural size 
 appropriate for the provided size.
 */
@interface BRCenteringScrollView : UIScrollView <UIScrollViewDelegate>

/** A delegate. */
@property (nonatomic, weak, nullable) id<BRScrollViewDelegate> scrollDelegate;

/**
 Flag to enable double-tap zoom support. If @c YES, then double-taps will be
 detected and treated as a zoom-in action, zooming in by @c doubleTapZoomIncrement
 to at most @c doubleTapMaxZoomLevel.
 */
@property (nonatomic, getter = isDoubleTapToZoom) IBInspectable BOOL doubleTapToZoom;

/** The increment by which to zoom in when a double-tap is detected. Defaults to @c 2. */
@property (nonatomic) IBInspectable CGFloat doubleTapZoomIncrement;

/**
 The maximum amount to allow double-tapping to zoom in to. Each double-tap will zoom
 the content in increments of @c doubleTapZoomIncrement until @c doubleTapMaxZoomLevel is
 reached, after which time the content will be scaled back to its initial zoom level.
 */
@property (nonatomic) IBInspectable CGFloat doubleTapMaxZoomLevel;

/** The @c UITapGestureRecognizer handling the double-tap to zoom. */
@property (nonatomic, readonly, strong) UITapGestureRecognizer *doubleTapRecognizer;

@end

NS_ASSUME_NONNULL_END
