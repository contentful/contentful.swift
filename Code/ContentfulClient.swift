//
//  ContentfulClient.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable
import Interstellar

public class ContentfulClient {
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

    public func fetchAsset(identifier: String, completion: Result<Asset> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("assets/\(identifier)"), completion)
    }

    public func fetchAsset(identifier: String) -> (NSURLSessionDataTask?, Signal<Asset>) {
        let signal = Signal<Asset>()
        let task = fetchAsset(identifier) { signal.update($0) }
        return (task, signal)
    }

    public func fetchContentType(identifier: String, completion: Result<ContentType> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("content_types/\(identifier)"), completion)
    }

    public func fetchContentTypes(completion: Result<ContentfulArray<ContentType>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("content_types"), completion)
    }

    public func fetchEntries(completion: Result<ContentfulArray<Entry>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("entries"), completion)
    }

    public func fetchEntries(matching: [String:AnyObject], completion: Result<ContentfulArray<Entry>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("entries", parameters: matching), completion)
    }

    public func fetchEntry(identifier: String, completion: Result<Entry> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("entries/\(identifier)"), completion)
    }

    public func fetchSpace(completion: Result<Space> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment(), completion)
    }

    private func fetch<T: Decodable>(url: NSURL?, _ completion: Result<T> -> Void) -> NSURLSessionDataTask? {
        if let url = url {
            let task = session.dataTaskWithURL(url) { (data, response, error) in
                if let data = data {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                        completion(.Success(try T.decode(json)))
                    } catch let error as DecodingError {
                        completion(.Error(ContentfulError.UnparseableJSON(data: data, errorMessage: error.debugDescription)))
                    } catch _ {
                        completion(.Error(ContentfulError.UnparseableJSON(data: data, errorMessage: "")))
                    }

                    return
                } else {
                    if let error = error {
                        completion(.Error(error))
                        return
                    }
                }

                completion(.Error(ContentfulError.InvalidHTTPResponse(response: response)))
            }

            task.resume()
            return task
        }

        completion(.Error(ContentfulError.InvalidURL(string: "")))
        return nil
    }

    private func URLForFragment(fragment: String = "", parameters: [String: AnyObject]? = nil) -> NSURL? {
        if let components = NSURLComponents(string: "\(scheme)://\(configuration.server)/spaces/\(spaceIdentifier)/\(fragment)") {
            if let parameters = parameters {
                components.queryItems = parameters.map() { (key, value) in NSURLQueryItem(name: key, value: value.description) }
            }

            if let url = components.URL {
                return url
            }
        }

        return nil
    }
}
