//
//  SignalUtils.swift
//  Contentful
//
//  Created by Boris Bügling on 01/12/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar


/// Takes closure that takes a Result of type U and returns a URLSessionData task.
public typealias SignalBang<U> = (@escaping (Result<U>) -> Void) -> URLSessionDataTask?

/// Takes a query pattern generic and a closure that takes a Result of type U and returns a URLSessionData task.
public typealias AsyncDataTask<QueryPattern, U> = (QueryPattern, @escaping (Result<U>) -> Void) -> URLSessionDataTask?


internal func toObservable<QueryPattern, ResultType>(parameter: QueryPattern,
               asyncDataTask: AsyncDataTask<QueryPattern, ResultType>) -> (task: URLSessionDataTask?, observable: Observable<Result<ResultType>>) {

    let observable = Observable<Result<ResultType>>()

    let task: URLSessionDataTask? = asyncDataTask(parameter) { result in
        observable.update(result)
    }

    return (task, observable)
}


public typealias TypeErasedAsyncDataTask<U, QueryPattern> = (U.Type, QueryPattern, @escaping (Result<U>) -> Void) -> URLSessionDataTask?

internal func toObservable<ResultType, QueryPattern>(_ resultType: ResultType.Type,
                                                     parameter: QueryPattern,
                                                     asyncDataTask: TypeErasedAsyncDataTask<ResultType, QueryPattern>) -> (task: URLSessionDataTask?, observable: Observable<Result<ResultType>>) {

    let observable = Observable<Result<ResultType>>()

    let task: URLSessionDataTask? = asyncDataTask(resultType, parameter) { result in
        observable.update(result)
    }

    return (task, observable)
}


internal func toObservable<ResultType>(closure: SignalBang<ResultType>) -> (task: URLSessionDataTask?, observable: Observable<Result<ResultType>>) {

    let observable = Observable<Result<ResultType>>()
    let task = closure { result in
        observable.update(result)
    }

    return (task, observable)
}
