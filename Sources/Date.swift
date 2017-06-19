//
//  Date.swift
//  Contentful
//
//  Created by JP Wright on 04/01/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

// Formatter and extensions pulled from: https://stackoverflow.com/a/28016692/4068264
public extension Date {

    public struct Formatter {

        public static let iso8601: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Foundation.Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            return formatter
        }()
    }

    /// Returns a `String` in the ISO8601 format.
    public var iso8601String: String {
        return Formatter.iso8601.string(from: self)
    }
}

public extension String {

    /// Return a `Date` object if the current String is in the right format.
    public var iso8601StringDate: Date? {
        return Date.Formatter.iso8601.date(from: self)
    }
}

public final class SysISO8601DateTransform: DateFormatterTransform {

    public init() {

        let formatter = Date.Formatter.iso8601
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Foundation.Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"

        super.init(dateFormatter: formatter)
    }
}
