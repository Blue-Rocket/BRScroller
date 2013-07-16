//
//  DemoTiledView.m
//  BRScrollerDemo
//
//  Created by Matt on 7/17/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "DemoTiledView.h"

#import <QuartzCore/QuartzCore.h>

@implementation DemoTiledView {
	CGFloat contentsScale;
}

+ (Class)layerClass {
	return [CATiledLayer class];
}

- (id)initWithFrame:(CGRect)frame{
    if ( (self = [super initWithFrame:frame]) ) {
		CATiledLayer *tiledLayer = (CATiledLayer *)[self layer];
		tiledLayer.tileSize = CGSizeMake(256, 256);
		tiledLayer.levelsOfDetail = 1;
		tiledLayer.levelsOfDetailBias = 3;
		tiledLayer.edgeAntialiasingMask = 0;
		tiledLayer.actions = [NSDictionary dictionaryWithObject:[NSNull null] forKey:@"sublayers"];
    }
    return self;
}

- (UIScrollView *)parentScrollView {
	UIView *v = self;
	Class clazz = [UIScrollView class];
	while ( v.superview != nil ) {
		v = v.superview;
		if ( [v isKindOfClass:clazz] ) {
			return (UIScrollView *)v;
		}
	}
	return nil;
}

#pragma mark Drawing

// thanks, ye ol' bithacks: http://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2Float
static unsigned int RoundedToPowerOf2(const float v) {
	unsigned int r;
	if ( v > 1.0 ) {
		float f = (ceilf(v) - 1);
		r = 1U << ((*(unsigned int*)(&f) >> 23) - 126);
	} else {
		r = 1;
	}
	return r;
}

- (void)drawRect:(CGRect)rect {
	// need empty impl for UIView to call drawLayer:inContext:
}

- (void)didMoveToWindow {
	log4Debug(@"Did move to window, contentsScale = %f", self.layer.contentsScale);
	// Retina display work-around: so 1024x1024 tiles are drawn instead of 512x512 tiles
	contentsScale = self.layer.contentsScale;
	self.layer.contentsScale = 1.0;
}

- (void)drawLayer:(CALayer *)theLayer inContext:(CGContextRef)context {
	const CGRect bounds = CGContextGetClipBoundingBox(context);
	const CGAffineTransform viewTransform = self.transform;
	UIScrollView *scroller = [self parentScrollView];
	const CGFloat scale = RoundedToPowerOf2(scroller.zoomScale * viewTransform.a) * contentsScale;
	log4Debug(@"Drawing tile rect %@ at scale %f", NSStringFromCGRect(bounds), scale);
	CGContextSetFillColorWithColor(context, [UIColor colorWithRed:((arc4random() % 255) / 255.0) green:((arc4random() % 255) / 255.0)
															   blue:((arc4random() % 255) / 255.0) alpha:1.0].CGColor);
	CGContextFillRect(context, bounds);
	NSString *num = [NSString stringWithFormat:@"%d,%d", (int)bounds.origin.x, (int)bounds.origin.y];
	UIFont *font = [UIFont boldSystemFontOfSize:ceilf(12 / scale)];
	CGSize textSize = [num sizeWithFont:font];
	const CGRect textFrame = CGRectMake(floorf(CGRectGetMidX(bounds) - textSize.width * 0.5),
										floorf(CGRectGetMidY(bounds) - textSize.height * 0.5),
										textSize.width, textSize.height);
	UIGraphicsPushContext(context); {
		[[UIColor whiteColor] set];
		[num drawInRect:textFrame withFont:font];
	} UIGraphicsPopContext();
}


@end
