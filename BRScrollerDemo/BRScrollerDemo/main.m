//
//  main.m
//  BRScrollerDemo
//
//  Created by Matt on 7/11/13.
//  Copyright (c) 2013 Blue Rocket. Distributable under the terms of the Apache License, Version 2.0.
//

#import <UIKit/UIKit.h>

#import <BRCocoaLumberjack/BRCocoaLumberjack.h>
#import "AppDelegate.h"

#if DEBUG
	const DDLogLevel ddLogLevel = DDLogLevelDebug;
#else
	const DDLogLevel ddLogLevel = DDLogLevelInfo;
#endif

int main(int argc, char *argv[])
{
	@autoreleasepool {
		BRLoggingSetupDefaultLogging();
	    return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
	}
}
