//
//  Query.swift
//  Contentful
//
//  Created by JP Wright on 06/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

public struct QueryParameter {

    static let contentType  = "content_type"
    static let select       = "select"
    static let order        = "order"
    static let limit        = "limit"
    static let skip         = "skip"
    static let include      = "include"
    static let locale       = "locale"
}


public enum QueryOperation {
    case equals(String)
    case doesNotEqual(String)
    case hasAll([String])
    case includes([String])
    case excludes([String])
    case exists(Bool)

    internal var operation: String {
        switch self {
        case .equals:
            return ""

        case .doesNotEqual:
            return "[ne]"

        case .hasAll:
            return "[all]"

        case .includes:
            return "[in]"

        case .excludes:
            return "[nin]"

        case .exists:
            return "[exists]"
        }
    }

//    internal static func validatecombinationsRecursively(operations: QueryOperation...) throws {
//        // TODO:
//    }
//
//    internal static func validateCombination(operation operationA: QueryOperation, operation operationB: QueryOperation) throws -> Bool {
//        switch (operationA, operationB) {
//        case (.equals, .equals):
//                return true
//        case (.doesNotEqual, .doesNotEqual):
//            return true
//        default:
//            fatalError("Unhandled combination")
//        }
//
//        return false
//    }

    internal var values: String {
        switch self {
        case .equals(let value):
            return value

        case .doesNotEqual(let value):
            return value

        case .hasAll(let values):
            return values.joined(separator: ",")

        case .includes(let values):
            return values.joined(separator: ",")

        case .excludes(let values):
            return values.joined(separator: ",")

        case .exists(let value):
            return value ? "true" : "false"
        }
    }
}

public struct Query<ContentType: ContentModel> {

    /// Query operation
    public static func query(where name: String, _ operation: QueryOperation, for locale: String? = nil) -> Query<ContentType> {
        let query = Query<ContentType>()
        return query.query(where: name, operation, for: locale)
    }

    public func query(where name: String, _ operation: QueryOperation, for locale: String? = nil) -> Query<ContentType> {

        // create parameter
        let parameter = name + operation.operation
        let argument = operation.values

        let parameters = self.parameters + [parameter: argument]

        let query = Query(contentTypeId: Query.contentTypeIdentifier(), parameters: parameters, locale: locale)

        return query
    }

    /// Select operation
    public static func select(fieldNames: [String], for locale: String? = nil) throws -> Query<ContentType> {
        let query = Query<ContentType>()
        return try query.select(fieldNames: fieldNames, for: locale)
    }

    public func select(fieldNames: [String], for locale: String? = nil) throws -> Query<ContentType> {
        return try select(fieldNames: fieldNames, contentTypeId: Query.contentTypeIdentifier(), locale: locale)
    }


    // MARK: Private


    private var contentTypeId: String?

    internal var parameters: [String: String] = [String: String]()

    private var locale: String? = Defaults.locale

    internal func queryParameters() -> [String: String] {
        var parameters = self.parameters

        if let contentTypeId = contentTypeId {
            parameters[QueryParameter.contentType] = contentTypeId
        }

        if let locale = locale {
            parameters[QueryParameter.locale] = locale
        }

        return parameters
    }

    private func select(fieldNames: [String], contentTypeId: String?, locale: String? = nil) throws -> Query<ContentType> {

        guard fieldNames.count < 100 else { throw QueryError.hitSelectionLimit }

        try Query.validate(selectedKeyPaths: fieldNames)

        let validSelections = Query.addSysIfNeeded(to: fieldNames).joined(separator: ",")

        let parameters = self.parameters + [QueryParameter.select: validSelections]
        let query = Query(contentTypeId: Query.contentTypeIdentifier(), parameters: parameters, locale: locale)

        return query
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
