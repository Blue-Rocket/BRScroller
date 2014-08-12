//
//  BRScrollerLogging.h
//  BRScroller
//
//  Created by Matt on 8/12/14.
//  Copyright (c) 2014 Blue Rocket. All rights reserved.
//

#define log4Error NSLog
#ifdef LOGGING
	#define log4Info NSLog
	#define log4Debug NSLog
	#define log4Trace NSLog
#else
	#define log4Info(...)
	#define log4Debug(...)
	#define log4Trace(...)
#endif
