//
//  BRCenteringScrollView.h
//  BRScroller
//
//  A UIScrollView designed to manage zoomable content. It keeps the content
//  centered, and keeps track of view size changes, keeping content in view
//  when possible, such as when the interface orientation changes.
//
//  This view is its own UIScrollViewDelegate. Setting the delegate property
//  to some other instance will not work. The managed content view is the one
//  returned by viewForZoomingInScrollView:, so subclasses should implement
//  that method and return the appropriate view, or the scrollDelegate should.
//  In addition, that view's sizeThatFits: method will be used to determine this
//  view's contentSize value. Thus the managed view should implement that method
//  in such a way that it returns the view's "natural" size appropriate for the
//  provided size.
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

#import "BRScrollViewDelegate.h"

@interface BRCenteringScrollView : UIScrollView <UIScrollViewDelegate>

@property (nonatomic, weak) id<BRScrollViewDelegate> scrollDelegate;

// double-tap zoom support: configure doubleTapToZoom to YES, then double-taps will be
// detected and treated as a zoom-in action.
@property (nonatomic, getter = isDoubleTapToZoom) IBInspectable BOOL doubleTapToZoom;

// the increment by which to zoom in when a double-tap is detected; defaults to 2
@property (nonatomic) IBInspectable CGFloat doubleTapZoomIncrement;

// the maximum amount to allow double-tapping to zoom in to; each double-tap will zoom
// the content in increments ofdoubleTapZoomIncrement until doubleTapMaxZoomLevel is
// reached, at which time the content will be scaled back to its initial zoom level
@property (nonatomic) IBInspectable CGFloat doubleTapMaxZoomLevel;

// read-only access to the UITapGestureRecognizer handling the double-tap to zoom
@property (nonatomic, readonly, strong) UITapGestureRecognizer *doubleTapRecognizer;

@end
