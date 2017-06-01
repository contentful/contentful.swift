//
//  SignalUtils.swift
//  Contentful
//
//  Created by Boris Bügling on 01/12/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar


typealias SignalBang<U> = (@escaping (Result<U>) -> Void) -> URLSessionDataTask?

// Take a QueryPattern to query on and closure that takes a Result of type U and reutrns a URLSessionData task...
typealias AsyncDataTask<QueryPattern, U> = (QueryPattern, @escaping  (Result<U>) -> Void) -> URLSessionDataTask?


func transformObservable<U, V, W>(closure: () -> (V, Observable<Result<U>>), mapper: @escaping (U) -> W?) -> (V, Observable<Result<W>>) {
    let signal = Observable<Result<W>>()
    let (value, sourceSignal) = closure()
    let next = sourceSignal.then { [weak signal] value in
        if let mappedValue = mapper(value) {
            signal?.update(Result.success(mappedValue))
        }
    }
    next.error { [weak signal] error in
        signal?.update(Result.error(error))
    }
    return (value, signal)
}

func toObservable<QueryPattern, ResultType>(parameter: QueryPattern,
               asyncDataTask: AsyncDataTask<QueryPattern, ResultType>) -> (task: URLSessionDataTask?, observable: Observable<Result<ResultType>>) {

    let observable = Observable<Result<ResultType>>()

    let task: URLSessionDataTask? = asyncDataTask(parameter) { result in
        observable.update(result)
    }

    return (task, observable)
}

func toObservable<ResultType>(closure: SignalBang<ResultType>) -> (task: URLSessionDataTask?, observable: Observable<Result<ResultType>>) {

    let observable = Observable<Result<ResultType>>()
    let task = closure { result in
        observable.update(result)
    }

    return (task, observable)
}
