//
//  ContentfulLogger.swift
//  Contentful
//
//  Created by JP Wright on 12/11/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

/// Implement this protocol in order to provide your own custom logger for the SDK to log messages to.
/// Your `CustomLogger` instance will only be passed message it should log according the set log level.
public protocol CustomLogger {
    /// Logs a message if the message being logged has a log level less than the level configured on the Logger instance. Logging with LogType `none` does nothing.
    func log(message: String)
}

/// A logger for outputting status messages to the console from Contentful SDK.
public enum ContentfulLogger {

    #if os(iOS) || os(tvOS) || os(watchOS) || os(macOS)
    /// The type of logger used to log messages; defaults to `NSLog` on iOS, tvOS, watchOS, macOS. Defaults to `print` on other platforms.
    public static var logType: LogType = .nsLog
    #else
    /// The type of logger used to log messages; defaults to `NSLog` on iOS, tvOS, watchOS, macOS. Defaults to `print` on other platforms.
    public static var logType: LogType = .print
    #endif

    /// The highest order of message types that should be logged. Defaults to `LogLevel.error`.
    public static var logLevel: LogLevel = .error

    /// An enum describing the types of messages to be logged.
    public enum LogLevel: Int {
        /// Log nothing to the console.
        case none = 0
        /// Only log errors to the console.
        case error
        /// Log messages when requests are sent, and when responses are received, as well as other useful information.
        case info
    }

    /// The type of logger to use.
    public enum LogType {
        /// Log using simple Swift print statements
        case print
        /// Log using NSLog.
        case nsLog
        /// Log using a custom logger.
        case custom(CustomLogger)
    }

    internal static func log(_ level: LogLevel, message: String) {
        guard level.rawValue <= self.logLevel.rawValue && level != .none else { return }

        var formattedMessage = "[Contentful] "
        switch level {
        case .error:
            formattedMessage += "Error: "
        default: break
        }
        formattedMessage += message

        switch self.logType {
        case .print:
            Swift.print(formattedMessage)
        case .nsLog:
            NSLog(formattedMessage)
        case .custom(let customLogger):
            customLogger.log(message: formattedMessage)
        }
    }
}
