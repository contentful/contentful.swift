//
//  DecondingTests.swift
//  Contentful
//
//  Created by Boris Bügling on 29/09/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import CatchingFire
import Nimble
import Quick

@testable import Contentful

class DecondingTests: QuickSpec {
    func jsonData(fileName: String) -> AnyObject {
        let path = NSString(string: "Data").stringByAppendingPathComponent(fileName)
        let data = NSData(contentsOfFile: NSBundle(forClass: DecondingTests.self).pathForResource(path, ofType: "json")!)
        return try! NSJSONSerialization.JSONObjectWithData(data!, options: [])
    }

    override func spec() {
        describe("Decoding data") {
            it("can decode assets") {
                AssertNoThrow {
                    let asset = try Asset.decode(self.jsonData("asset"))

                    expect(asset.identifier).to(equal("5VPbSI9VSM2Suq4eMEIGOS"))
                    expect(asset.type).to(equal("Asset"))
                    expect(asset.URL).to(equal(NSURL(string: "https://images.contentful.com/fsnczri66h17/5VPbSI9VSM2Suq4eMEIGOS/937e4ebd25917ae20be0d3bacd0511af/3D5423B9-558E-41DB-95B5-EF7406FC1AB7.jpg_dl_1")))
                }
            }
        }
    }
}
