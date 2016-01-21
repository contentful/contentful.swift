//
//  SyncSpace.swift
//  Contentful
//
//  Created by Boris Bügling on 20/01/16.
//  Copyright © 2016 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

public final class SyncSpace {
    internal(set) public var assets = [Asset]()
    internal(set) public var entries = [Entry]()

    internal(set) public var client: ContentfulClient? = nil
    internal(set) public var syncToken = ""

    internal init() {}

    public func sync(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<SyncSpace> -> Void) -> NSURLSessionDataTask? {
        guard let client = self.client else {
            completion(.Error(ContentfulError.InvalidClient()))
            return nil
        }

        var parameters = matching
        parameters["sync_token"] = syncToken
        let (task, signal) = client.sync(parameters)

        signal.next { space in
            self.assets += space.assets
            self.entries += space.entries
            self.syncToken = space.syncToken

            completion(.Success(self))
        }.error {
            completion(.Error($0))
        }

        return task
    }
}
