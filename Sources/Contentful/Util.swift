//
//  Util.swift
//  Contentful
//
//  Created by JP Wright on 07.03.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation


public func +=<K, V> (left: [K: V], right: [K: V]) -> [K: V] {
    var result = left
    right.forEach { (key, value) in result[key] = value }
    return result
}

public func +<K, V> (left: [K: V], right: [K: V]) -> [K: V] {
    return left += right
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
