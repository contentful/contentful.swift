//
//  Util.swift
//  Contentful
//
//  Created by JP Wright on 07.03.18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

/// Utility method to add two dictionaries of the same time.
public func +=<K, V> (left: [K: V], right: [K: V]) -> [K: V] {
    var result = left
    right.forEach { key, value in result[key] = value }
    return result
}

/// Utility method to add two dictionaries of the same time.
public func +<K, V> (left: [K: V], right: [K: V]) -> [K: V] {
    return left += right
}

/// Convenience methods for reading from dictionaries without conditional casts.
public extension Dictionary where Key: ExpressibleByStringLiteral {

    /// Extract the String at the specified fieldName.
    ///
    /// - Parameter key: The name of the field to extract the `String` from.
    /// - Returns: The `String` value, or `nil` if data contained is not convertible to a `String`.
    func string(at key: Key) -> String? {
        return self[key] as? String
    }

    /// Extracts the array of `String` at the specified fieldName.
    ///
    /// - Parameter key: The name of the field to extract the `[String]` from
    /// - Returns: The `[String]`, or nil if data contained is not convertible to an `[String]`.
    func strings(at key: Key) -> [String]? {
        return self[key] as? [String]
    }

    /// Extracts the `Int` at the specified fieldName.
    ///
    /// - Parameter key: The name of the field to extract the `Int` value from.
    /// - Returns: The `Int` value, or `nil` if data contained is not convertible to an `Int`.
    func int(at key: Key) -> Int? {
        return self[key] as? Int
    }

    /// Extracts the `Date` at the specified fieldName.
    ///
    /// - Parameter key: The name of the field to extract the `Date` value from.
    /// - Returns: The `Date` value, or `nil` if data contained is not convertible to a `Date`.
    func int(at key: Key) -> Date? {
        let dateString = self[key] as? String
        let date = dateString?.iso8601StringDate
        return date
    }

    /// Extracts the `Entry` at the specified fieldName.
    ///
    /// - Parameter key: The name of the field to extract the `Entry` from.
    /// - Returns: The `Entry` value, or `nil` if data contained does not have contain a Link referencing an `Entry`.
    func linkedEntry(at key: Key) -> Entry? {
        let link = self[key] as? Link
        let entry = link?.entry
        return entry
    }

    /// Extracts the `Asset` at the specified fieldName.
    ///
    /// - Parameter key: The name of the field to extract the `Asset` from.
    /// - Returns: The `Asset` value, or `nil` if data contained does not have contain a Link referencing an `Asset`.
    func linkedAsset(at key: Key) -> Asset? {
        let link = self[key] as? Link
        let asset = link?.asset
        return asset
    }

    /// Extracts the `[Entry]` at the specified fieldName.
    ///
    /// - Parameter key: The name of the field to extract the `[Entry]` from.
    /// - Returns: The `[Entry]` value, or `nil` if data contained does not have contain a Link referencing an `Entry`.
    func linkedEntries(at key: Key) -> [Entry]? {
        let links = self[key] as? [Link]
        let entries = links?.compactMap { $0.entry }
        return entries
    }

    /// Extracts the `[Asset]` at the specified fieldName.
    ///
    /// - Parameter key: The name of the field to extract the `[Asset]` from.
    /// - Returns: The `[Asset]` value, or `nil` if data contained does not have contain a Link referencing an `[Asset]`.
    func linkedAssets(at key: Key) -> [Asset]? {
        let links = self[key] as? [Link]
        let assets = links?.compactMap { $0.asset }
        return assets
    }

    /// Extracts the `Bool` at the specified fieldName.
    ///
    /// - Parameter key: The name of the field to extract the `Bool` value from.
    /// - Returns: The `Bool` value, or `nil` if data contained is not convertible to a `Bool`.
    func bool(at key: Key) -> Bool? {
        return self[key] as? Bool
    }


    /// Extracts the `Contentful.Location` at the specified fieldName.
    ///
    /// - Parameter key: The name of the field to extract the `Contentful.Location` value from.
    /// - Returns: The `Contentful.Location` value, or `nil` if data contained is not convertible to a `Contentful.Location`.
    func location(at key: Key) -> Location? {
        let coordinateJSON = self[key] as? [String: Any]
        guard let longitude = coordinateJSON?["lon"] as? Double else { return nil }
        guard let latitude = coordinateJSON?["lat"] as? Double else { return nil }
        let location = Location(latitude: latitude, longitude: longitude)
        return location
    }
}

// Convenience protocol and accompanying extension for extracting the type of data wrapped in an Optional.
internal protocol OptionalProtocol {
    static func wrappedType() -> Any.Type
}

extension Optional: OptionalProtocol {
    internal static func wrappedType() -> Any.Type {
        return Wrapped.self
    }
}
