//
//  LinkTests.swift
//  Contentful
//
//  Created by JP Wright on 22/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import Foundation
import XCTest
import Nimble
import DVR

class LinkTests: XCTestCase {

    func testGetLinkFromFieldValueThatIsAlreadyALink() {
        let entry = Entry(localizedField: ["":["":""]])
        let link = Link.entry(entry)
        let newLink = Link.link(from: link)
        expect(newLink).toNot(beNil())
    }
}
