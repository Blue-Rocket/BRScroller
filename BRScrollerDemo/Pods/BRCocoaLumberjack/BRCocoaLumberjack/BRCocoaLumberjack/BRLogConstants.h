//
//  BRLogConstants.h
//  BRCocoaLumberjack
//
//  Created by Matt on 8/16/13.
//  Copyright (c) 2013 Blue Rocket, Inc. Distributable under the terms of the Apache License, Version 2.0.
//

#ifndef BRCocoaLumberjack_BRLogConstants_h
#define BRCocoaLumberjack_BRLogConstants_h

extern int BRCLogLevel;

// We want to use the following log levels:
//
// Error
// Warn
// Info
// Debug
// Trace
//
// First undefine the default stuff we don't want to use.

#undef LOG_FLAG_ERROR
#undef LOG_FLAG_WARN
#undef LOG_FLAG_INFO
#undef LOG_FLAG_DEBUG
#undef LOG_FLAG_VERBOSE

#undef LOG_LEVEL_ERROR
#undef LOG_LEVEL_WARN
#undef LOG_LEVEL_INFO
#undef LOG_LEVEL_DEBUG
#undef LOG_LEVEL_VERBOSE

#undef LOG_ERROR
#undef LOG_WARN
#undef LOG_INFO
#undef LOG_DEBUG
#undef LOG_VERBOSE

#undef DDLogError
#undef DDLogWarn
#undef DDLogInfo
#undef DDLogDebug
#undef DDLogVerbose

// Now define everything how we want it

#define LOG_FLAG_ERROR   (1 << 0)  // 0...00001
#define LOG_FLAG_WARN    (1 << 1)  // 0...00010
#define LOG_FLAG_INFO    (1 << 2)  // 0...00100
#define LOG_FLAG_DEBUG   (1 << 3)  // 0...01000
#define LOG_FLAG_TRACE   (1 << 4)  // 0...10000
#define LOG_FLAG_VERBOSE LOG_FLAG_TRACE

#define LOG_LEVEL_ERROR   (LOG_FLAG_ERROR)                     // 0...00001
#define LOG_LEVEL_WARN    (LOG_FLAG_WARN   | LOG_LEVEL_ERROR)  // 0...00011
#define LOG_LEVEL_INFO    (LOG_FLAG_INFO   | LOG_LEVEL_WARN)   // 0...00111
#define LOG_LEVEL_DEBUG   (LOG_FLAG_DEBUG  | LOG_LEVEL_INFO)   // 0...01111
#define LOG_LEVEL_TRACE   (LOG_FLAG_TRACE  | LOG_LEVEL_DEBUG)  // 0...11111
#define LOG_LEVEL_VERBOSE LOG_LEVEL_TRACE

#define LOG_ERROR   (BRLogLevelForClass([self class]) & LOG_FLAG_ERROR)
#define LOG_WARN    (BRLogLevelForClass([self class]) & LOG_FLAG_WARN)
#define LOG_INFO    (BRLogLevelForClass([self class]) & LOG_FLAG_INFO)
#define LOG_DEBUG   (BRLogLevelForClass([self class]) & LOG_FLAG_DEBUG)
#define LOG_TRACE   (BRLogLevelForClass([self class]) & LOG_FLAG_TRACE)
#define LOG_VERBOSE LOG_TRACE

#endif
