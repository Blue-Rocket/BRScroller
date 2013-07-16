//
//  DemoZoomingTiledView.m
//  BRScrollerDemo
//
//  Created by Matt on 7/17/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "DemoZoomingTiledView.h"

#import "DemoTiledView.h"

@implementation DemoZoomingTiledView {
	DemoTiledView *tiledView;
}

@synthesize tiledView;

- (id)initWithFrame:(CGRect)frame {
    if ( (self = [super initWithFrame:frame]) ) {
        [self initializeDemoZoomingTiledViewDefaults];
    }
    return self;
}

- (void)initializeDemoZoomingTiledViewDefaults {
	tiledView = [[DemoTiledView alloc] initWithFrame:self.bounds];
	[self addSubview:tiledView];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return tiledView;
}

@end
