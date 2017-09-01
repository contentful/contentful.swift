//
//  Client+Query.swift
//  Contentful
//
//  Created by JP Wright on 09.08.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

extension Client {
    /**
     Fetch a collection of Entries from Contentful matching the specified query. This method does not
     specify the content_type in the query parameters, so the entries returned in the results can be
     of any type.

     - Parameter query: The Query object to match results againts.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchEntries(with query: Query,
                                                then completion: @escaping ResultsHandler<ArrayResponse<Entry>>) -> URLSessionDataTask? {

        let url = URL(forComponent: "entries", parameters: query.parameters)
        return fetch(url: url, then: completion)
    }

    /**
     Fetch a collection of Assets from Contentful matching the specified query.

     - Parameter query: The Query object to match results againts.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchAssets(with query: AssetQuery,
                                               then completion: @escaping ResultsHandler<ArrayResponse<Asset>>) -> URLSessionDataTask? {

        let url = URL(forComponent: "assets", parameters: query.parameters)
        return fetch(url: url, then: completion)
    }
}
