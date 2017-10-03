//
//  ContentModellable.swift
//  Contentful
//
//  Created by JP Wright on 15/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation

public typealias ContentTypeId = String

/**
 Classes conforming to this protocol can be passed into your ContentModel to leverage the type system 
 to return instances of your own model classes when using methods such as:

 ```
 func fetchMappedEntries(with query: Query,
    then completion: @escaping ResultsHandler<MappedContent>) -> URLSessionDataTask?
 ```
 */
public protocol EntryModellable: class, Decodable {

    /// The identifier of the Contentful content type that will map to this type of `EntryPersistable`
    static var contentTypeId: ContentTypeId { get }
}


// Convenience protocol and accompanying extension for extracting the type of data wrapped in an Optional.
internal protocol OptionalProtocol {
    static func wrappedType() -> Any.Type
}

extension Optional: OptionalProtocol {
    static func wrappedType() -> Any.Type {
        return Wrapped.self
    }
}
