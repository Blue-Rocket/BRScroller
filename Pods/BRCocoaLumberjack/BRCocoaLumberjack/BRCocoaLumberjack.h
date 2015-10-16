//
//  BRCocoaLumberjack.h
//  BRCocoaLumberjack
//
//  Created by Matt on 8/16/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#import <CocoaLumberjack/CocoaLumberjack.h>
#import <BRCocoaLumberjack/BRLogConstants.h>
#import <BRCocoaLumberjack/BRLogging.h>

// Always log Errors
#define DDLogError(frmt, ...)    LOG_MAYBE(NO,                BRLogLevelForClass([self class]), DDLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogCError(frmt, ...)   LOG_MAYBE(NO,                BRCLogLevel, DDLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

// log4Cocoa compatibility
#define log4Error DDLogError
#define log4CError DDLogCError

#ifdef LOGGING

#define DDLogWarn(frmt, ...)     LOG_MAYBE(LOG_ASYNC_ENABLED, BRLogLevelForClass([self class]), DDLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogInfo(frmt, ...)     LOG_MAYBE(LOG_ASYNC_ENABLED, BRLogLevelForClass([self class]), DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogDebug(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, BRLogLevelForClass([self class]), DDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogVerbose(frmt, ...)  LOG_MAYBE(LOG_ASYNC_ENABLED, BRLogLevelForClass([self class]), DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define DDLogCWarn(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogCInfo(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogCDebug(frmt, ...)   LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define DDLogCVerbose(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

// 1.x backwards compatibility
#define DDLogTrace DDLogVerbose
#define DDLogCTrace DDLogCVerbose

// log4Cocoa compatibility
#define log4Warn DDLogWarn
#define log4Info DDLogInfo
#define log4Debug DDLogDebug
#define log4Trace DDLogTrace

#define log4CWarn DDLogCWarn
#define log4CInfo DDLogCInfo
#define log4CDebug DDLogCDebug
#define log4CTrace DDLogCTrace

#else

#define DDLogWarn(...)
#define DDLogInfo(...)
#define DDLogDebug(...)
#define DDLogVerbose(...)
#define DDLogTrace(...)

#define DDLogCWarn(...)
#define DDLogCInfo(...)
#define DDLogCDebug(...)
#define DDLogCVerbose(...)
#define DDLogCTrace(...)

// log4Cocoa compatibility
#define log4Warn(...)
#define log4Info(...)
#define log4Debug(...)
#define log4Trace(...)

#define log4CWarn(...)
#define log4CInfo(...)
#define log4CDebug(...)
#define log4CTrace(...)

#endif
