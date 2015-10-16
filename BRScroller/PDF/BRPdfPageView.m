//
//  BRPdfPageView.m
//  BRScroller
//
//  Created by Matt on 16/10/15.
//  Copyright © 2015 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRPdfPageView.h"

@implementation BRPdfPageView

- (id)initWithFrame:(CGRect)frame {
	if ( (self = [super initWithFrame:frame]) ) {
		self.contentMode = UIViewContentModeRedraw;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	[self drawInRect:rect context:UIGraphicsGetCurrentContext()];
}

@end
