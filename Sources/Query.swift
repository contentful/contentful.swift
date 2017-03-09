//
//  Query.swift
//  Contentful
//
//  Created by JP Wright on 06/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar
import Decodable


public protocol Queryable {
    associatedtype ContentType
}

public protocol AssetModel: class {

    var identifier: String { get }

    init?(identifier: String?)

    func update(with fields: [String: Any])
}

public protocol ContentModel: AssetModel {

    static var contentTypeId: String { get }

//    func updateLinks(with includes: [String: Any])
}

public extension AssetModel {

    init?(link: Any?) {
        if let entry = link as? Entry {
            self.init(identifier: entry.identifier)
            self.update(with: entry.fields)
            return
        }
        if let asset = link as? Asset {
            self.init(identifier: asset.identifier)
            self.update(with: asset.fields)
            return
        }
        let identifier = Contentful.identifier(for: link)
        self.init(identifier: identifier)
    }
}

internal func identifier(for link: Any?) -> String? {
    guard let link = link as? [String: Any] else { return nil }
    let sys = link["sys"] as? [String: Any]
    let identifier = sys?["id"] as? String
    return identifier
}


public protocol Query {


    /// All queries supported by the Contentful Delivery API require the content_type parameter to be specified.
    var contentTypeId: String { get }

    var locale: String { get }

    func queryParameters() -> [String: String]
}


public struct SelectQuery<QueryableType>: Query, Queryable where QueryableType: ContentModel {

    public typealias ContentType = QueryableType

    public let contentTypeId: String

    public var locale: String

    var selectedFieldNames: [String]

    static func select(fieldNames: [String], locale: String = Defaults.locale) throws -> SelectQuery<QueryableType> {
        return try select(fieldNames: fieldNames, contentTypeId: QueryableType.contentTypeId, locale: locale)
    }

    static func select(fieldNames: [String], contentTypeId: String, locale: String = Defaults.locale) throws -> SelectQuery<QueryableType> {
        guard fieldNames.count < 100 else { throw QueryError.hitSelectionLimit() }

        let fieldNamePaths = fieldNames.map { return "fields.\($0)" }

        try validate(selectedKeyPaths: fieldNamePaths)

        return SelectQuery(contentTypeId: QueryableType.contentTypeId, locale: locale, selectedFieldNames: fieldNamePaths)
    }

    static private func validate(selectedKeyPaths: [String]) throws {
        for fieldKeyPath in selectedKeyPaths {
            guard fieldKeyPath.isValidSelection() else {
                throw QueryError.invalidSelection(fieldKeyPath: fieldKeyPath)
            }
        }
    }

    public func queryParameters() -> [String: String] {
        var parameters = [String: String]()
        let validSelections = addSysIfNeeded(to: selectedFieldNames)
        parameters["content_type"] = contentTypeId
        parameters["locale"] = locale
        parameters["select"] = validSelections.joined(separator: ",")
        return parameters
    }

    private func addSysIfNeeded(to selectedFieldNames: [String]) -> [String] {
        var completeSelections = selectedFieldNames
        if !completeSelections.contains("sys") {
            completeSelections.append("sys")
        }
        return completeSelections
    }
}

extension String {

    func isValidSelection() -> Bool {
        if characters.split(separator: ".").count > 2 {
            return false
        }
        return true
    }
}
