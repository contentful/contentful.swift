//
//  SignalUtils.swift
//  Contentful
//
//  Created by Boris Bügling on 01/12/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar


public typealias SignalBang<U> = (@escaping (Result<U>) -> Void) -> URLSessionDataTask?

// Take a QueryPattern to query on and closure that takes a Result of type U and reutrns a URLSessionData task...
public typealias AsyncDataTask<QueryPattern, U> = (QueryPattern, @escaping (Result<U>) -> Void) -> URLSessionDataTask?

internal func toObservable<QueryPattern, ResultType>(parameter: QueryPattern,
               asyncDataTask: AsyncDataTask<QueryPattern, ResultType>) -> (task: URLSessionDataTask?, observable: Observable<Result<ResultType>>) {

    let observable = Observable<Result<ResultType>>()

    let task: URLSessionDataTask? = asyncDataTask(parameter) { result in
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
