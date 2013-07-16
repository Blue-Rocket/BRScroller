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

@interface BRCenteringScrollView : UIScrollView

@property (nonatomic, weak) id<BRScrollViewDelegate> scrollDelegate;

@end
