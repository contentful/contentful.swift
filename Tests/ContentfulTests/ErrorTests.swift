//
//  ErrorTests.swift
//  Contentful
//
//  Created by JP Wright on 11.10.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

@testable import Contentful
import XCTest
import DVR
import Nimble

class ErrorTests: XCTestCase {


    static let client = TestClientFactory.testClient(withCassetteNamed:  "ErrorTests")

    override class func setUp() {
        super.setUp()
        (client.urlSession as? DVR.Session)?.beginRecording()
    }

    override class func tearDown() {
        super.tearDown()
        (client.urlSession as? DVR.Session)?.endRecording()
    }

    func testErrorMessageForInvalidPath() {
        let expectation = self.expectation(description: "Invalid path")
        
        ErrorTests.client.fetch(CCollection<Entry>.self, .where(valueAtKeyPath: "sys.888", .equals("GO"))) { result in
            switch result {
            case .success:
                fail("Request should not succeed")
            case .error(let error as APIError):
                // The DVR recorder fails to record not 200 status codes, so using a regex to check the status code intead (it returns 0 since the recorder is plugging it as nil).
                let expectedRegexString =
                """
                HTTP status code \\d+: The query you sent was invalid. Probably a filter or ordering specification is not applicable to the type of a field.
                The path \"sys.888\" is not recognized.
                Contentful Request ID: \\w+$
                """ 
                let regex = try! NSRegularExpression(pattern: expectedRegexString, options: [])
                let matches = regex.matches(in: error.debugDescription, options: [], range: NSRange(location: 0, length: error.debugDescription.count))
                expect(matches.count).to(equal(1))
            case .error:
                fail("Error returned should be an APIError")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }

}
