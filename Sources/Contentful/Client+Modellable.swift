//
//  Client+Modellable.swift
//  Contentful
//
//  Created by JP Wright on 01.08.17.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

extension Client {
    /**
     Fetch a collection of Entries from Contentful matching the specified query.

     - Parameter query: The Query object to match results againts.
     - Returns: An Observable for the resulting `MappedContent` container.
     */
    @discardableResult public func fetchMappedEntries(with query: Query) -> Observable<Result<MixedMappedArrayResponse>> {
        let asyncDataTask: AsyncDataTask<Query, MixedMappedArrayResponse> = fetchMappedEntries(with:then:)
        return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetches all entries and includes matching the passed in `Query`. The completion handler returned will return a `MappedContent` object which
     contains an array of `Asset`s and a dictionary of ContentTypeId's to arrays of `EntryDecodable` types of your own definition.

     - Parameter query: The Query object to match results against.
     - Parameter completion: A handler being called on completion of the request containing a `MappedContent` instance.

     - Returns: The data task being used, enables cancellation of requests. If there is no `contentModel` property set on the Client, this method
                will return nil.
     */
    @discardableResult public func fetchMappedEntries(with query: Query,
                                                      then completion: @escaping ResultsHandler<MixedMappedArrayResponse>) -> URLSessionDataTask? {
        let url = URL(forComponent: "entries", parameters: query.parameters)

        return fetch(url: url, then: completion)
    }

    /**
     Fetch a collection of Entries of a specified content type matching the query. The content_type
     parameter is specified by passing in a generic parameter: a model class conforming to `EntryDecodable`.

     - Parameter query: A QueryOn object to match results of the specified EntryDecodable against.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests. If there is no `contentModel` property set on the Client, this method
                will return nil.

     */
    @discardableResult public func fetchMappedEntries<EntryType>(with query: QueryOn<EntryType>,
        then completion: @escaping ResultsHandler<MappedArrayResponse<EntryType>>) -> URLSessionDataTask? {

        let url = URL(forComponent: "entries", parameters: query.parameters)

        return fetch(url: url, then: completion)
    }

    /**
     Fetch a collection of Entries of a specified content type matching the query. The content_type
     parameter is specified by passing in a generic parameter: a model class conforming to `EntryDecodable`.

     - Parameter query: A QueryOn object to match results of the specified EntryDecodable against.

     - Returns: A tuple of data task and an observable for the resulting array of EntryDecodable types.
     */
    @discardableResult public func fetchMappedEntries<EntryType>(with query: QueryOn<EntryType>)
        -> Observable<Result<MappedArrayResponse<EntryType>>> {

            let asyncDataTask: AsyncDataTask<QueryOn<EntryType>, MappedArrayResponse<EntryType>> = fetchMappedEntries(with:then:)
            return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }
}
