//
//  LoggerTests.swift
//  Contentful
//
//  Created by JP Wright on 13/11/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import Foundation
import XCTest

class CustomTestLogger: CustomLogger {
    init() {}

    var currentMessage: String?

    func reset() {
        currentMessage = nil
    }

    func log(message: String) {
        currentMessage = message
    }
}

class LoggerTests: XCTestCase {

    func testLoggerRespectsLogLevel() {
        let customLogger = CustomTestLogger()

        ContentfulLogger.logType = .custom(customLogger)

        // Log level is none, so nothing should be logged.
        ContentfulLogger.logLevel = .none
        var message = "This message shouldn't be returned"
        ContentfulLogger.log(.info, message: message)
        XCTAssertNil(customLogger.currentMessage)

        customLogger.reset()

        // Log level is error, so error messages should be logged, and info should not
        ContentfulLogger.logLevel = .error
        message = "This message SHOULD be logged as an error, not logged as info"
        ContentfulLogger.log(.error, message: message)
        XCTAssertEqual(customLogger.currentMessage, "[Contentful] Error: " + message)
        customLogger.reset()
        ContentfulLogger.log(.info, message: message)
        XCTAssertNil(customLogger.currentMessage) // Since log level is error, logging info should not work.

        // At log level info, everything should be logged, except for none messages which are never logged.
        ContentfulLogger.logLevel = .info
        message = "This message SHOULD be logged as long as logLevel is not none."
        ContentfulLogger.log(.error, message: message)
        XCTAssertEqual(customLogger.currentMessage,  "[Contentful] Error: " + message)
        customLogger.reset()
        XCTAssertNil(customLogger.currentMessage) // Sanity check on reset
        ContentfulLogger.log(.info, message: message)
        XCTAssertEqual(customLogger.currentMessage,  "[Contentful] " + message)

        // Log to none, nothing should log.
        customLogger.reset()
        XCTAssertNil(customLogger.currentMessage) // Sanity check on reset
        ContentfulLogger.log(.none, message: message)
        XCTAssertNil(customLogger.currentMessage)
    }
}
