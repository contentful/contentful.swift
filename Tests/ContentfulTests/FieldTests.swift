//
//  Copyright © 2020 Contentful GmbH. All rights reserved.
//

import Contentful
import XCTest

class FieldTests: XCTestCase {

    func testFieldTypeArray() {
        let itemType = FieldType.entry
        let json: [String: Any] = [
            "id": "id-1",
            "name": "name-1",
            "disabled": false,
            "localized": false,
            "required": true,
            "type": FieldType.array.rawValue,
            "items": [
                "type": FieldType.link.rawValue,
                "linkType": itemType.rawValue
            ]
        ]

        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        let field = try! JSONDecoder().decode(Field.self, from: data)

        XCTAssertEqual(field.itemType, itemType)
    }

    func testFieldTypeLink() {
        let itemType = FieldType.entry
        let json: [String: Any] = [
            "id": "id-1",
            "name": "name-1",
            "disabled": false,
            "localized": false,
            "required": true,
            "type": FieldType.link.rawValue,
            "linkType": itemType.rawValue
        ]

        let data = try! JSONSerialization.data(withJSONObject: json, options: [])
        let field = try! JSONDecoder().decode(Field.self, from: data)

        XCTAssertEqual(field.itemType, itemType)
    }
}
