//
//  StructuredTextRenderingTests.swift
//  Contentful
//
//  Created by JP Wright on 18.09.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import Nimble
import DVR
import Foundation

class StructuredTextRenderingTests: XCTestCase {

    func testRenderingDocument() {
        let expectation = self.expectation(description: "")

        let client = Client(spaceId: "jd7yc4wnatx3",
                            accessToken: "6256b8ef7d66805ca41f2728271daf27e8fa6055873b802a813941a0fe696248",
                            contentTypeClasses: [STTest.self, EmbeddedEntry.self, AtomicStructuredTextModel.self])
        client.fetchArray(of: STTest.self, matching: QueryOn<STTest>.where(sys: .id, .equals("4BupPSmi4M02m0U48AQCSM"))) { result in
            switch result {
            case .success(let arrayResponse):
                expect(arrayResponse.items.count).to(equal(1))

                let output = DefaultDocumentRenderer(styling: Styling()).render(document: arrayResponse.items.first!.body)
                print(output)

            case .error(let error):
                fail("\(error)")
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10.0, handler: nil)
    }

}
