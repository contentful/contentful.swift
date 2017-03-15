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

public enum QueryOperation {
    case equal(to: String)
    case notEqual(to: String)
    case multipleValues([String])
    case inclusion([String])
    case exclusion([String])
    case exists(is: Bool)

    internal var operation: String {
        switch self {
        case .equal:
            return ""

        case .notEqual:
            return "[ne]"

        case .multipleValues:
            return "[all]"

        case .inclusion:
            return "[in]"

        case .exclusion:
            return "[nin]"

        case .exists:
            return "[exists]"
        }
    }

    internal func validate() throws {
        // TODO:
    }

    internal var values: String {
        switch self {
        case .equal(let value):
            return value

        case .notEqual(let value):
            return value

        case .multipleValues(let values):
            return values.joined(separator: ",")

        case .inclusion(let values):
            return values.joined(separator: ",")

        case .exclusion(let values):
            return values.joined(separator: ",")

        case .exists(let value):
            return value ? "true" : "false"
        }
    }
}

public struct Query<ContentType: ContentModel> {

    /// Query operation
    public static func query(where name: String, _ operation: QueryOperation) -> Query<ContentType> {
        // check that names start with "sys." or "fields."

        // validate
        // create parameter
        let parameter = name + operation.operation
        let argument = operation.values

        let query = Query(contentTypeId: contentTypeIdentifier(), locale: "en-US", parameter: parameter, argument: argument)
        return query
    }

    /// Select operation
    public static func select(fieldNames: [String], locale: String = Defaults.locale) throws -> Query<ContentType> {
        return try select(fieldNames: fieldNames, contentTypeId: contentTypeIdentifier(), locale: locale)
    }

    public let contentTypeId: String?

    public let locale: String

    private let parameter: String

    private let argument: String

    private static func select(fieldNames: [String], contentTypeId: String?, locale: String = Defaults.locale) throws -> Query<ContentType> {
        guard fieldNames.count < 100 else { throw QueryError.hitSelectionLimit() }

        try validate(selectedKeyPaths: fieldNames)
        let validSelections = addSysIfNeeded(to: fieldNames).joined(separator: ",")

        return Query(contentTypeId: contentTypeId, locale: locale, parameter: "select", argument: validSelections)
    }

    private static func contentTypeIdentifier() -> String? {
        var contentTypeId: String? = nil

        if let type = ContentType.self as? EntryModel.Type {
            contentTypeId = type.contentTypeId
        }
        return contentTypeId
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

        if let contentTypeId = contentTypeId {
            parameters["content_type"] = contentTypeId
        }

        parameters["locale"] = locale
        parameters[parameter] = argument
        return parameters
    }

//    private static func validate(queryArguments: [String], contentTypeId: String?, operation: QueryOperation) throws {
//        for argument in queryArguments {
//            if argument.hasPrefix("fields.") && contentTypeId == nil {
//                throw QueryError.invalidSelection(fieldKeyPath: argument)
//            }
//        }
//        try operation.validate()
//    }

    private static func addSysIfNeeded(to selectedFieldNames: [String]) -> [String] {
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
