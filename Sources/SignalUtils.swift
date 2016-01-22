//
//  SignalUtils.swift
//  Contentful
//
//  Created by Boris Bügling on 01/12/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

func convert_signal<U, V, W>(closure: () -> (V, Signal<U>), mapper: (U) -> W?) -> (V, Signal<W>) {
    let signal = Signal<W>()
    let (value, sourceSignal) = closure()
    sourceSignal.next {
        if let value = mapper($0) {
            signal.update(value)
        }
    }.error { signal.update($0) }
    return (value, signal)
}

func signalify<T, U, V>(parameter: T, _ closure: (T, (Result<U>) -> ()) -> V) -> (V, Signal<U>) {
    let signal = Signal<U>()
    let value = closure(parameter) { signal.update($0) }
    return (value, signal)
}

func signalify<U, V>(closure: ((Result<U>) -> ()) -> V) -> (V, Signal<U>) {
    let signal = Signal<U>()
    let value = closure { signal.update($0) }
    return (value, signal)
}

class Network {
    var sessionConfigurator: ((NSURLSessionConfiguration) -> ())?

    private var session: NSURLSession {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        if let sessionConfigurator = sessionConfigurator {
            sessionConfigurator(sessionConfiguration)
        }
        return NSURLSession(configuration: sessionConfiguration)
    }

    func fetch(url: NSURL, _ completion: Result<NSData> -> Void) -> NSURLSessionDataTask {
        let task = session.dataTaskWithURL(url) { (data, response, error) in
            if let data = data {
                completion(.Success(data))
                return
            }

            if let error = error {
                completion(.Error(error))
                return
            }

            completion(.Error(Error.InvalidHTTPResponse(response: response)))
        }

        task.resume()
        return task
    }

    func fetch(url: NSURL) -> (NSURLSessionDataTask, Signal<NSData>) {
        return signalify(url, fetch)
    }
}
