//
//  CDAClient.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Interstellar

public class CDAClient {
    private let configuration: Configuration
    private let session: NSURLSession
    private let spaceIdentifier: String

    private var scheme: String { return configuration.secure ? "https" : "http" }

    public init(spaceIdentifier: String, accessToken: String, configuration: Configuration = Configuration()) {
        let sessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfiguration.HTTPAdditionalHeaders = [ "Authorization": "Bearer \(accessToken)" ]

        session = NSURLSession(configuration: sessionConfiguration)

        self.configuration = configuration
        self.spaceIdentifier = spaceIdentifier
    }

    public func fetchAsset(identifier: String, completion: Result<Asset> -> Void) -> NSURLSessionDataTask {
        let task = session.dataTaskWithURL(URLForFragment("assets/\(identifier)")) { (data, response, error) in
            if let data = data {
                let asset = Asset(data: data)
                asset.scheme = self.scheme
                completion(.Success(asset))
            } else {
                if let error = error {
                    completion(.Error(error))
                }
            }
        }

        task.resume()
        return task
    }

    public func fetchContentType(identifier: String, completion: Result<ContentType> -> Void) -> NSURLSessionDataTask {
        let task = session.dataTaskWithURL(URLForFragment("content_types/\(identifier)")) { (data, response, error) in
            if let data = data {
                completion(.Success(ContentType(data: data)))
            } else {
                if let error = error {
                    completion(.Error(error))
                }
            }
        }

        task.resume()
        return task
    }

    public func fetchEntries(completion: Result<CDAArray<Entry>> -> Void) -> NSURLSessionDataTask {
        let task = session.dataTaskWithURL(URLForFragment("entries")) { (data, response, error) in
            if let data = data {
                completion(.Success(CDAArray(data: data)))
            } else {
                if let error = error {
                    completion(.Error(error))
                }
            }
        }

        task.resume()
        return task
    }

    public func fetchEntry(identifier: String, completion: Result<Entry> -> Void) -> NSURLSessionDataTask {
        let task = session.dataTaskWithURL(URLForFragment("entries/\(identifier)")) { (data, response, error) in
            if let data = data {
                completion(.Success(Entry(data: data)))
            } else {
                if let error = error {
                    completion(.Error(error))
                }
            }
        }

        task.resume()
        return task
    }

    public func fetchSpace(completion: Result<Space> -> Void) -> NSURLSessionDataTask {
        let task = session.dataTaskWithURL(URLForFragment()) { (data, response, error) in
            if let data = data {
                completion(.Success(Space(data: data)))
            } else {
                if let error = error {
                    completion(.Error(error))
                }
            }
        }

        task.resume()
        return task
    }

    private func URLForFragment(fragment: String = "", parameters: [NSObject: AnyObject]? = nil) -> NSURL {
        let components = NSURLComponents(string: "\(scheme)://\(configuration.server)/spaces/\(spaceIdentifier)/\(fragment)")
        return (components!.URL)!
    }
}
