//
//  ContentfulClient.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable
import Foundation
import Interstellar

public class ContentfulClient {
    private let configuration: Configuration
    private let network = Network()
    private let spaceIdentifier: String

    private var scheme: String { return configuration.secure ? "https" : "http" }

    public init(spaceIdentifier: String, accessToken: String, configuration: Configuration = Configuration()) {
        network.sessionConfigurator = { (sessionConfiguration) in
            sessionConfiguration.HTTPAdditionalHeaders = [ "Authorization": "Bearer \(accessToken)" ]
        }

        self.configuration = configuration
        self.spaceIdentifier = spaceIdentifier
    }

    private func fetch<T: Decodable>(url: NSURL?, _ completion: Result<T> -> Void) -> NSURLSessionDataTask? {
        if let url = url {
            let (task, signal) = network.fetch(url)

            signal.next { (data) in
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                    completion(.Success(try T.decode(json)))
                } catch let error as DecodingError {
                    completion(.Error(ContentfulError.UnparseableJSON(data: data, errorMessage: error.debugDescription)))
                } catch _ {
                    completion(.Error(ContentfulError.UnparseableJSON(data: data, errorMessage: "")))
                }
            }.error { completion(.Error($0)) }

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

extension ContentfulClient {
    public func fetchAsset(identifier: String, completion: Result<Asset> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("assets/\(identifier)"), completion)
    }

    public func fetchAsset(identifier: String) -> (NSURLSessionDataTask?, Signal<Asset>) {
        return signalify(identifier, fetchAsset)
    }

    public func fetchAssets(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<ContentfulArray<Asset>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("assets", parameters: matching), completion)
    }

    public func fetchAssets(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<ContentfulArray<Asset>>) {
        return signalify(matching, fetchAssets)
    }
}

extension ContentfulClient {
    public func fetchContentType(identifier: String, completion: Result<ContentType> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("content_types/\(identifier)"), completion)
    }

    public func fetchContentType(identifier: String) -> (NSURLSessionDataTask?, Signal<ContentType>) {
        return signalify(identifier, fetchContentType)
    }

    public func fetchContentTypes(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<ContentfulArray<ContentType>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("content_types", parameters: matching), completion)
    }

    public func fetchContentTypes(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<ContentfulArray<ContentType>>) {
        return signalify(matching, fetchContentTypes)
    }
}

extension ContentfulClient {
    public func fetchEntries(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<ContentfulArray<Entry>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("entries", parameters: matching), completion)
    }

    public func fetchEntries(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<ContentfulArray<Entry>>) {
        return signalify(matching, fetchEntries)
    }

    public func fetchEntry(identifier: String, completion: Result<Entry> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("entries/\(identifier)"), completion)
    }

    public func fetchEntry(identifier: String) -> (NSURLSessionDataTask?, Signal<Entry>) {
        return signalify(identifier, fetchEntry)
    }
}

extension ContentfulClient {
    public func fetchSpace(completion: Result<Space> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment(), completion)
    }

    public func fetchSpace() -> (NSURLSessionDataTask?, Signal<Space>) {
        return signalify(fetchSpace)
    }
}
