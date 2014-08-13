//
//  BRScrollerUtilities.c
//  BRScroller
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#include "BRScrollerUtilities.h"

#include <math.h>
#include <sys/param.h>

inline bool BRFloatsAreEqual(CGFloat a, CGFloat b) {
	const CGFloat d = a - b;
	return (d < 0 ? -d : d) < 1e-4;
}

inline CGSize BRAspectSizeToFit(CGSize aSize, CGSize maxSize) {
	CGFloat scale = 1.0;
	if ( aSize.width > 0.0 && aSize.height > 0.0 ) {
		CGFloat dw = maxSize.width / aSize.width;
		CGFloat dh = maxSize.height / aSize.height;
		scale = dw < dh ? dw : dh;
	}
	return CGSizeMake(MIN(floorf(maxSize.width), ceilf(aSize.width * scale)),
					  MIN(floorf(maxSize.height), ceilf(aSize.height * scale)));
}
