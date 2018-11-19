//
//  Result.swift
//  Contentful
//
//  Created by JP Wright on 30/05/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

/// Conform to ResultType to use your own result type, e.g. from other libraries with Contentful.
public protocol ResultType {
    /// Describes the contained successful type of this result.
    associatedtype Value

    /// Return an error if the result is unsuccessful, otherwise nil.
    var error: Error? { get }

    /// Return the value if the result is successful, otherwise nil.
    var value: Value? { get }
}


/// A result contains the result of a computation or task. It might be either successfull
/// with an attached value or a failure with an attached error (which conforms to Swift 2's
/// ErrorType). You can read more about the implementation in
/// [this blog post](http://jensravens.de/a-swifter-way-of-handling-errors/).
public enum Result<T>: ResultType {
    case success(T)
    case error(Error)

    /// Initialize a result containing a successful value.
    public init(success value: T) {
        self = Result.success(value)
    }

    /// Initializes a result containing an error
    public init(error: Error) {
        self = .error(error)
    }

    /// Direct access to the content of the result as an optional. If the result was a success,
    /// the optional will contain the value of the result.
    public var value: T? {
        switch self {
        case let .success(v): return v
        case .error: return nil
        }
    }

    /// Direct access to the error of the result as an optional. If the result was an error,
    /// the optional will contain the error of the result.
    public var error: Error? {
        switch self {
        case .success: return nil
        case .error(let x): return x
        }
    }
}

/// Provides a default value for failed results.
public func ?? <T> (result: Result<T>, defaultValue: @autoclosure () -> T) -> T {
    switch result {
    case .success(let x): return x
    case .error: return defaultValue()
    }
}
