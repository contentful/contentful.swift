//
//  Date.swift
//  Contentful
//
//  Created by JP Wright on 04/01/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

extension Date {

    static let GMT_STRING_SIZE = Int(strlen("1971-02-03T09:16:06Z") + 1)

    private func epochToISO8601GMTString(epoch : Int) -> String? {
        var epoch = epoch
        var time: UnsafeMutablePointer<tm>
        time = gmtime(&epoch)

        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Date.GMT_STRING_SIZE)
        strftime(buffer, Date.GMT_STRING_SIZE, "%FT%TZ", time)
        let string = String(validatingUTF8: buffer)
        return string
    }

    func toISO8601GMTString() -> String? {
        let epoch = Int(self.timeIntervalSince1970)
        return epochToISO8601GMTString(epoch: epoch)
    }
}
