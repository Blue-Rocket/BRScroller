//
//  MultiViewController.h
//  BRScrollerDemo
//
//  Demonstration of using multiple BRScrollerView instances witihin the same view hierarchy.
//  A full-screen scroller is used to represent "full detail" pages of content. A small
//  "ribbon" scroller at the bottom of the screen is used to represent "thumbnails" of the
//  corresponding full detail page content. Tapping on a thumbnail causes the detail page
//  to animate into view.
//
//  Created by Matt on 7/17/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BaseDemoViewController.h"

@class BRScrollerView;

@interface MultiViewController : BaseDemoViewController

@property (nonatomic, strong) IBOutlet BRScrollerView *scrollView;
@property (nonatomic, strong) IBOutlet BRScrollerView *thumbView;

@end
