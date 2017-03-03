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


public protocol Query {

    /// All queries supported by the Contentful Delivery API require the content_type parameter to be specified.
    var contentTypeId: String { get }

    var locale: String { get }

    func queryParameters() -> [String: String]
}


public struct SelectQuery: Query {

    public let contentTypeId: String

    public var locale: String

    var selectedFieldNames: [String]

    static func select(fieldNames: [String], contentTypeId: String, locale: String = Defaults.locale) throws -> Query {
        guard fieldNames.count < 100 else { throw QueryError.hitSelectionLimit() }

        let fieldNamePaths = fieldNames.map { return "fields.\($0)" }

        try validate(selectedKeyPaths: fieldNamePaths)

        return SelectQuery(contentTypeId: contentTypeId, locale: locale, selectedFieldNames: fieldNamePaths)
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
