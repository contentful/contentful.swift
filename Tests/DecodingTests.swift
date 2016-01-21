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

import Contentful

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

                    expect(asset.identifier).to(equal("nyancat"))
                    expect(asset.type).to(equal("Asset"))
                    expect(try asset.URL()).to(equal(NSURL(string: "https://images.contentful.com/cfexampleapi/4gp6taAwW4CmSgumq2ekUm/9da0cd1936871b8d72343e895a00d611/Nyan_cat_250px_frame.png")))
                }
            }

            it("can decode spaces") {
                AssertNoThrow {
                    let space = try Space.decode(self.jsonData("space"))

                    expect(space.identifier).to(equal("cfexampleapi"))
                    expect(space.name).to(equal("Contentful Example API"))
                    expect(space.locales.count).to(equal(2))
                    expect(space.locales[0].name).to(equal("English"))
                    expect(space.locales[0].code).to(equal("en-US"))
                    expect(space.locales[0].isDefault).to(equal(true))
                }
            }

            it("can decode localized entries") {
                AssertNoThrow {
                    var entry = try Entry.decode(self.jsonData("localized"))

                    expect(entry.identifier).to(equal("nyancat"))
                    expect(entry.fields["name"] as? String).to(equal("Nyan Cat"))

                    entry.locale = "tlh"

                    expect(entry.fields["name"] as? String).to(equal("Nyan vIghro'"))
                }
            }

            it("can decode sync responses") {
                AssertNoThrow {
                    let syncSpace = try SyncSpace.decode(self.jsonData("sync"))

                    expect(syncSpace.assets.count).to(equal(4))
                    expect(syncSpace.entries.count).to(equal(11))
                    expect(syncSpace.syncToken).to(equal("w5ZGw6JFwqZmVcKsE8Kow4grw45QdybCnV_Cg8OASMKpwo1UY8K8bsKFwqJrw7DDhcKnM2RDOVbDt1E-wo7CnDjChMKKGsK1wrzCrBzCqMOpZAwOOcOvCcOAwqHDv0XCiMKaOcOxZA8BJUzDr8K-wo1lNx7DnHE"))
                }
            }

            it("can decode sync responses with deleted assets") {
                AssertNoThrow {
                    let syncSpace = try SyncSpace.decode(self.jsonData("deleted-asset"))

                    expect(syncSpace.assets.count).to(equal(0))
                    expect(syncSpace.entries.count).to(equal(0))
                }
            }

            it("can decode sync responses with deleted entries") {
                AssertNoThrow {
                    let syncSpace = try SyncSpace.decode(self.jsonData("deleted"))

                    expect(syncSpace.assets.count).to(equal(0))
                    expect(syncSpace.entries.count).to(equal(0))
                }
            }
        }
    }
}
