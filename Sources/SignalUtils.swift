//
//  SignalUtils.swift
//  Contentful
//
//  Created by Boris Bügling on 01/12/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

class Network {
    var sessionConfigurator: ((NSURLSessionConfiguration) -> ())?

    private var session: NSURLSession {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        if let sessionConfigurator = sessionConfigurator {
            sessionConfigurator(sessionConfiguration)
        }
        return NSURLSession(configuration: sessionConfiguration)
    }

    func fetch(url: NSURL, completion: Result<NSData> -> Void) -> NSURLSessionDataTask {
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
}
