//
//  FieldTypeTests.swift
//
//  Copyright © 2020 Contentful GmbH. All rights reserved.
//

import Contentful
import XCTest

class FieldTypeTests: XCTestCase {

    func testFieldTypes() {
        XCTAssertEqual(FieldType.array.rawValue, "Array")
        XCTAssertEqual(FieldType.asset.rawValue, "Asset")
        XCTAssertEqual(FieldType.boolean.rawValue, "Boolean")
        XCTAssertEqual(FieldType.date.rawValue, "Date")
        XCTAssertEqual(FieldType.entry.rawValue, "Entry")
        XCTAssertEqual(FieldType.integer.rawValue, "Integer")
        XCTAssertEqual(FieldType.link.rawValue, "Link")
        XCTAssertEqual(FieldType.location.rawValue, "Location")
        XCTAssertEqual(FieldType.number.rawValue, "Number")
        XCTAssertEqual(FieldType.object.rawValue, "Object")
        XCTAssertEqual(FieldType.symbol.rawValue, "Symbol")
        XCTAssertEqual(FieldType.text.rawValue, "Text")
        XCTAssertEqual(FieldType.none.rawValue, "None")
        XCTAssertEqual(FieldType.richText.rawValue, "RichText")
    }
}
