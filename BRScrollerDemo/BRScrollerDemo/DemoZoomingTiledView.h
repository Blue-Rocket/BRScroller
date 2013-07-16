//
//  DemoZoomingTiledView.h
//  BRScrollerDemo
//
//  Created by Matt on 7/17/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <BRScroller/BRScroller.h>

@class DemoTiledView;

@interface DemoZoomingTiledView : BRCenteringScrollView

@property (nonatomic, strong, readonly) DemoTiledView *tiledView;

@end
