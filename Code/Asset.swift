//
//  Asset.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation
import Interstellar

#if os(iOS)
import UIKit
#endif

public struct Asset : Resource {
    public let sys: [String:AnyObject]
    public let fields: [String:AnyObject]

    public let identifier: String
    public let type: String
    public let URL: NSURL

    private var session: NSURLSession {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        return NSURLSession(configuration: sessionConfiguration)
    }

    private func fetch(completion: Result<NSData> -> Void) -> NSURLSessionDataTask {
        let task = session.dataTaskWithURL(URL) { (data, response, error) in
            if let data = data {
                completion(.Success(data))
                return
            }

            if let error = error {
                completion(.Error(error))
                return
            }

            completion(.Error(ContentfulError.InvalidHTTPResponse(response: response)))
        }

        task.resume()
        return task
    }

    public func fetch() -> (NSURLSessionDataTask, Signal<NSData>) {
        let signal = Signal<NSData>()
        let task = fetch { signal.update($0) }
        return (task, signal)
    }

#if os(iOS)
    public func fetchImage() -> (NSURLSessionDataTask, Signal<UIImage>) {
        let signal = Signal<UIImage>()
        let (task, dataSignal) = fetch()
        dataSignal.next() {
            if let image = UIImage(data: $0) {
                signal.update(image)
            }
        }.error() { signal.update($0) }
        return (task, signal)
    }
#endif
}
