//
//  DateFormatterCache.swift
//  Contentful
//
//  Created by Donny Wals on 05/08/2024.
//

import Foundation

class DateFormatterCache {
    static let shared = DateFormatterCache()
    
    private let queue = DispatchQueue(label: "com.contentful.formattercache")
    private var cache = [String: DateFormatter]()
    
    private init() {}
    
    func get(_ format: String, timeZone: TimeZone? = nil) -> DateFormatter {
        return queue.sync {
            if let formatter = cache[format] {
                return formatter
            }
            
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            // The locale and timezone properties must be exactly as follows to have a true, time-zone agnostic (i.e. offset of 00:00 from UTC) ISO stamp.
            formatter.locale = Foundation.Locale(identifier: "en_US_POSIX")
            formatter.timeZone = timeZone ?? TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = format
            
            cache[format] = formatter
            
            return formatter
        }
    }
}
