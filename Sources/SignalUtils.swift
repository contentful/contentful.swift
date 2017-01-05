//
//  SignalUtils.swift
//  Contentful
//
//  Created by Boris Bügling on 01/12/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

// TODO: Name these generics better
func convert_signal<U, V, W>(closure: () -> (V, Observable<Result<U>>), mapper: @escaping (U) -> W?) -> (V, Observable<Result<W>>) {
    let signal = Observable<Result<W>>()
    let (value, sourceSignal) = closure()
    let next = sourceSignal.then { value in
        if let mappedValue = mapper(value) {
            signal.update(Result.success(mappedValue))
        }
    }
    next.error { error in
        signal.update(Result.error(error))
    }
    return (value, signal)
}

// FIXME: Rename typealias'
typealias SignalBang<U> = (@escaping (Result<U>) -> Void) -> URLSessionDataTask?
typealias SignalObservation<T, U> = (T, @escaping  (Result<U>) -> Void) -> URLSessionDataTask?

// TODO: Better method names
func signalify<ParameterType, ResultType>(parameter: ParameterType, closure: SignalObservation<ParameterType, ResultType>) -> (URLSessionDataTask?, Observable<Result<ResultType>>) {
    let signal = Observable<Result<ResultType>>()
    let value: URLSessionDataTask? = closure(parameter) { signal.update($0) }
    return (value, signal)
}

func signalify<U>(closure: SignalBang<U>) -> (URLSessionDataTask?, Observable<Result<U>>) {
    let signal = Observable<Result<U>>()
    let value = closure { signal.update($0) }
    return (value, signal)
}

class Network {
    var sessionConfigurator: ((URLSessionConfiguration) -> ())?

    fileprivate var session: URLSession {
        let sessionConfiguration = URLSessionConfiguration.default
        if let sessionConfigurator = sessionConfigurator {
            sessionConfigurator(sessionConfiguration)
        }
        return URLSession(configuration: sessionConfiguration)
    }

    func fetch(url: URL, completion: @escaping (Result<Data>) -> Void) -> URLSessionDataTask {
        let task = session.dataTask(with: url, completionHandler: { (data, response, error) in
            if let data = data {
                completion(.success(data))
                return
            }

            if let error = error {
                completion(.error(error))
                return
            }

            completion(.error(SDKError.invalidHTTPResponse(response: response)))
        }) 

        task.resume()
        return task
    }

    func fetch(url: URL) -> (URLSessionDataTask?, Observable<Result<Data>>) {
        let closure: SignalObservation<URL, Data> = fetch
        return signalify(parameter: url, closure: closure)
    }
}
