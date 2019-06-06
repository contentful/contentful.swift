//
//  Date.swift
//  Contentful
//
//  Created by JP Wright on 04/01/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

// Formatter and extensions pulled from: https://stackoverflow.com/a/28016692/4068264
// and https://stackoverflow.com/a/46538676/4068264
public extension Date {

    // An array of 4 date formats: the format present on `sys` properties in Contentful,
    // and the 3 formats used when creating entries in the Contentful web app. See this reference
    // for date symbols: http://userguide.icu-project.org/formatparse/datetime
    internal static let supportedFormats: [String] = [
        // Fractional seconds, as seen in `sys.updatedAt` and `sys.createdAt`
        "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX",
        "yyyy-MM-dd",
        "yyyy-MM-dd'T'HH:mm",
        // Handle UTC offsets.
        "yyyy-MM-dd'T'HH:mmxxx",
        "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    ]

    /// A small error type thrown when the date found in JSON cannot be deserialized.
    enum Error: String, Swift.Error {
        /// The error thrown when a date string returned in an API response cannot be parsed by the SDK.
        case unsupportedDateFormat
    }

    /// A formatter ready to handle iso8601 dates: normalized string output to an offset of 0 from UTC.
    static func iso8601Formatter(timeZone: TimeZone? = nil) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        // The locale and timezone properties must be exactly as follows to have a true, time-zone agnostic (i.e. offset of 00:00 from UTC) ISO stamp.
        formatter.locale = Foundation.Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone ?? TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return formatter
    }

    /// A custom for deserializing dates that come from Contentful
    /// This method first attempts to deserialize ISO8601 internetDateTime with fractional seconds
    /// then falls back to attempt the three other ISO8601 variants that the Contentful web app
    /// enables for editing date fields.
    /// - parameter decoder: The Decoder used to deserialize JSON from Contentful.
    /// - throws: Error.unsupportedDateFormat if the date isn't one of the three formats the web app supports
    ///           or the format used by Contentful `sys` properties.
    static func variableISO8601Strategy(_ decoder: Decoder) throws -> Date {
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)

        let timeZone = decoder.timeZone
        let formatter = Date.iso8601Formatter(timeZone: timeZone)

        for format in Date.supportedFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                return date
            }
        }
        throw Error.unsupportedDateFormat
    }

    /// Returns a `String` in the ISO8601 format.
    var iso8601String: String {
        return Date.iso8601Formatter().string(from: self)
    }
}

public extension String {

    /// Return a `Date` object if the current String is in the right format.
    var iso8601StringDate: Date? {
        return Date.iso8601Formatter().date(from: self)
    }
}
