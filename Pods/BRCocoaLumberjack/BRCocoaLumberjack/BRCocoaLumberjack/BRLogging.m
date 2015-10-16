//
//  BRLogging.m
//  BRCocoaLumberjack
//
//  Created by Matt on 8/16/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRLogging.h"

#import <objc/runtime.h>
#import "BRLogFormatter.h"
#import "BRLogConstants.h"
#import <CocoaLumberjack/DDASLLogger.h>
#import <CocoaLumberjack/DDTTYLogger.h>

// our global C function logging level
int BRCLogLevel;

// global dictionary of class-level logging configuration
static NSMutableDictionary *BRLogLevelClassMap;

// global default Objective-C logging level
static int BRDefaultLogLevel;

static void configureDynamicLogFromDictionary(NSDictionary *localEnv);

void BRLoggingSetupDefaultLogging() {
	BRLoggingSetupDefaultLoggingWithBundle([NSBundle mainBundle]);
}

void BRLoggingSetupDefaultLoggingWithBundle(NSBundle *bundle) {
	NSString *envFilePath = [bundle pathForResource:@"LocalEnvironment" ofType:@"plist"];
	NSDictionary *dynamic = [NSDictionary dictionaryWithContentsOfFile:envFilePath];
	if ( dynamic != nil ) {
		NSLog(@"Logging configuration loaded from %@", envFilePath);
	}
	BRLoggingSetupLogging(@[[DDASLLogger sharedInstance], [DDTTYLogger sharedInstance]],
	                      [[BRLogFormatter alloc] init],
	                      LOG_LEVEL_INFO,
	                      dynamic);
}

void BRLoggingSetupDefaultLogLevels(int defaultLevel, int defaultCLevel) {
	BRCLogLevel = defaultLevel;
	BRDefaultLogLevel = defaultCLevel;
	NSLog(@"Default log level set to %d; default C log level set to %d", defaultLevel, defaultCLevel);
}

void BRLoggingSetupLogging(NSArray *loggers, id<DDLogFormatter> formatter, int defaultLevel, NSDictionary *dynamicLogging) {
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
	    BRLogLevelClassMap = [[NSMutableDictionary alloc] initWithCapacity:4];
	});
	BRLoggingSetupDefaultLogLevels(defaultLevel, defaultLevel);
	[DDLog removeAllLoggers];
	for ( id<DDLogger> logger in loggers ) {
		[DDLog addLogger:logger];
		[logger setLogFormatter:formatter];
	}

	configureDynamicLogFromDictionary(dynamicLogging);
}

int BRLogLevelForClass(Class aClass) {
	NSNumber *logLevel = [BRLogLevelClassMap valueForKey:NSStringFromClass(aClass)];
	if ( logLevel == nil ) {
		Class superClass = aClass;
		while ( ( superClass = class_getSuperclass(superClass) ) ) {
			NSNumber *superLogLevel = [BRLogLevelClassMap valueForKey:NSStringFromClass(superClass)];
			if ( superLogLevel != nil ) {
				logLevel = superLogLevel;
				break;
			}
		}
	}
	return (logLevel) ? [logLevel intValue] : BRDefaultLogLevel;
}

static int logLevelForKey(NSString *levelString) {
	if ( [levelString isEqualToString:@"error"] ) {
		return LOG_LEVEL_ERROR;
	} else if ( [levelString isEqualToString:@"warn"] ) {
		return LOG_LEVEL_WARN;
	} else if ( [levelString isEqualToString:@"info"] ) {
		return LOG_LEVEL_INFO;
	} else if ( [levelString isEqualToString:@"debug"] ) {
		return LOG_LEVEL_DEBUG;
	} else if ( [levelString isEqualToString:@"trace"] ) {
		return LOG_LEVEL_TRACE;
	}
	return -1;
}

static void configureDynamicLogFromDictionary(NSDictionary *localEnv) {
	[BRLogLevelClassMap removeAllObjects];
	id logging = [localEnv valueForKey:@"logging"];
	if ( [logging isKindOfClass:[NSDictionary class]] ) {
		NSDictionary *loggingMap = (NSDictionary *)logging;
		for ( NSString *key in[loggingMap allKeys] ) {
			NSString *value = [loggingMap valueForKey:key];
			int logLevel = logLevelForKey([value lowercaseString]);
			if ( logLevel != (int)-1 ) {
				if ( [key isEqualToString:@"default"] ) {
					BRLoggingSetupDefaultLogLevels(logLevel, logLevel);
				} else {
					NSLog(@"Configuring class %@ log level %@ (%d)", key, value, logLevel);
					[BRLogLevelClassMap setObject:@(logLevel) forKey:key];
				}
			}
		}
	}
}
