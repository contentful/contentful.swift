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
    
    func testErrorMessageForInvalidPath() {
        let expectation = self.expectation(description: "Invalid path")
        let client = Client(spaceId: "cfexampleapi", accessToken: "b4c0n73n7fu1")
        client.fetchEntries(with: Query(where: "sys.888", .equals("GO"))) { result in
            switch result {
            case .success:
                fail("Request should not succeed")
            case .error(let error):
                expect((error as! ContentfulError).debugDescription).to(equal("The query you sent was invalid. Probably a filter or ordering specification is not applicable to the type of a field." + " " + "The path \"sys.888\" is not recognized"))
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0, handler: nil)
    }

}
