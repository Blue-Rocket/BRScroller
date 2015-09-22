//
//  BRLogFormatter.m
//  BRCocoaLumberjack
//
//  Created by Matt on 8/16/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import "BRLogFormatter.h"

#import "BRLogConstants.h"

@implementation BRLogFormatter {
	NSDateFormatter *dateFormatter;
}

- (id)init {
	if ( (self = [super init]) ) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateFormatter setDateFormat:@"MMddHHmm:ss.SSS"];
	}
	return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage {
	NSString *logLevel;
	switch ( logMessage->_flag ) {
		case LOG_FLAG_ERROR: logLevel = @"ERROR"; break;

		case LOG_FLAG_WARN: logLevel = @"WARN "; break;

		case LOG_FLAG_INFO: logLevel = @"INFO "; break;

		case LOG_FLAG_DEBUG: logLevel = @"DEBUG"; break;

		case LOG_FLAG_TRACE: logLevel = @"TRACE"; break;

		default: logLevel = @"OTHER"; break;
	}

	NSString *ts = [dateFormatter stringFromDate:(logMessage->_timestamp)];
	NSString *paddedThreadId = [logMessage->_threadID stringByPaddingToLength:6 withString:@" " startingAtIndex:0];

	return [NSString stringWithFormat:@"%@ %@ %@ %@:%lu %@| %@",
	        logLevel,
	        ts,
	        paddedThreadId,
	        logMessage->_fileName,
	        (unsigned long)logMessage->_line,
	        logMessage->_function,
	        logMessage->_message];
}

@end
