//
//  SignalUtils.swift
//  Contentful
//
//  Created by Boris Bügling on 01/12/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

func convert_signal<U, V, W>(_ closure: () -> (V, Signal<U>), mapper: (U) -> W?) -> (V, Signal<W>) {
    let signal = Signal<W>()
    let (value, sourceSignal) = closure()
    _ = sourceSignal.next {
        if let value = mapper($0) {
            signal.update(value)
        }
    }.error { signal.update($0) }
    return (value, signal)
}

func signalify<T, U, V>(_ parameter: T, _ closure: (T, (Result<U>) -> ()) -> V) -> (V, Signal<U>) {
    let signal = Signal<U>()
    let value = closure(parameter) { signal.update($0) }
    return (value, signal)
}

func signalify<U, V>(_ closure: ((Result<U>) -> ()) -> V) -> (V, Signal<U>) {
    let signal = Signal<U>()
    let value = closure { signal.update($0) }
    return (value, signal)
}

class Network {
    var sessionConfigurator: ((URLSessionConfiguration) -> ())?

    private var session: URLSession {
        let sessionConfiguration = URLSessionConfiguration.default()
        if let sessionConfigurator = sessionConfigurator {
            sessionConfigurator(sessionConfiguration)
        }
        return URLSession(configuration: sessionConfiguration)
    }

    func fetch(_ url: URL, _ completion: (Result<NSData>) -> Void) -> URLSessionDataTask {
        let task = session.dataTask(with: url) { (data, response, error) in
            if let data = data {
                completion(.Success(data))
                return
            }

            if let error = error {
                completion(.Error(error))
                return
            }

            completion(.Error(Error.invalidHTTPResponse(response: response)))
        }

        task.resume()
        return task
    }

    func fetch(_ url: NSURL) -> (URLSessionDataTask, Signal<NSData>) {
        return signalify(url as URL, fetch)
    }
}
