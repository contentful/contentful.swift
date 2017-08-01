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
     Fetch a collection of Assets from Contentful matching the specified query.

     - Parameter query: The Query object to match results againts.
     - Returns: An Observable forr the resulting `MappedContent` container.
     */
    @discardableResult public func fetchMappedEntries(with query: Query) -> Observable<Result<MappedContent>> {
        let asyncDataTask: AsyncDataTask<Query, MappedContent> = fetchMappedEntries(with:then:)
        return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }

    /**
     Fetches all entries and includes matching the passed in `Query`. The completion handler returned will return a `MappedContent` object which
     contains an array of `Asset`s and a dictionary of ContentTypeId's to arrays of `EntryModellable` types of your own defining.

     - Parameter query: The Query object to match results against.
     - Parameter completion: A handler being called on completion of the request containing a `MappedContent` instance.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchMappedEntries(with query: Query,
                                                      then completion: @escaping ResultsHandler<MappedContent>) -> URLSessionDataTask? {

        let url = URL(forComponent: "entries", parameters: query.parameters)

        return fetch(url: url) { (result: Result<ArrayResponse<Entry>>) in
            let mappedResult: Result<MappedContent> = result.flatMap { entriesArrayResponse in
                // FIXME: remove implicitly unwrapped optionals.
                let mappedContent = entriesArrayResponse.toMappedContent(for: self.contentModel!)
                return Result.success(mappedContent)
            }
            completion(mappedResult)
        }
    }

    /**
     Fetch a collection of Entries of a specified content type matching the query. The content_type
     parameter is specified by passing in a generic parameter: a model class conforming to `EntryModellable`.

     - Parameter query: A QueryOn object to match results of the specified EntryModellable against.
     - Parameter completion: A handler being called on completion of the request.

     - Returns: The data task being used, enables cancellation of requests.
     */
    @discardableResult public func fetchMappedEntries<EntryType>(with query: QueryOn<EntryType>,
                                                      then completion: @escaping ResultsHandler<MappedArrayResponse<EntryType>>) -> URLSessionDataTask? where EntryType: EntryModellable {

        let url = URL(forComponent: "entries", parameters: query.parameters)

        return fetch(url: url) { (result: Result<ArrayResponse<Entry>>) in

            let transformedResult: Result<MappedArrayResponse<EntryType>> = result.flatMap { entriesArrayResponse in
                return Result.success(entriesArrayResponse.toMappedArrayResponse(for: self.contentModel!))
            }
            completion(transformedResult)
        }
    }

    /**
     Fetch a collection of Entries of a specified content type matching the query. The content_type
     parameter is specified by passing in a generic parameter: a model class conforming to `EntryModellable`.

     - Parameter query: A QueryOn object to match results of the specified EntryModellable against.

     - Returns: A tuple of data task and an observable for the resulting array of EntryModellable types.
     */
    @discardableResult public func fetchMappedEntries<EntryType>(with query: QueryOn<EntryType>)
        -> Observable<Result<MappedArrayResponse<EntryType>>> where EntryType: EntryModellable {

            let asyncDataTask: AsyncDataTask<QueryOn<EntryType>, MappedArrayResponse<EntryType>> = fetchMappedEntries(with:then:)
            return toObservable(parameter: query, asyncDataTask: asyncDataTask).observable
    }
}
