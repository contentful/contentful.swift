//
//  Client.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Clock
import Decodable
import Foundation
import Interstellar

/// Client object for performing requests against the Contentful API
public class Client {
    private let configuration: Configuration
    private let network = Network()
    private let spaceIdentifier: String

    private var server: String {
        if configuration.previewMode && configuration.server == DEFAULT_SERVER {
            return "preview.contentful.com"
        }
        return configuration.server
    }

    private(set) var space: Space?

    private var scheme: String { return configuration.secure ? "https" : "http" }

    /**
     Initializes a new Contentful client instance

     - parameter spaceIdentifier: The space you want to perform requests against
     - parameter accessToken:     The access token used for authorization
     - parameter configuration:   Custom configuration of the client

     - returns: An initialized client instance
     */
    public init(spaceIdentifier: String, accessToken: String, configuration: Configuration = Configuration()) {
        network.sessionConfigurator = { (sessionConfiguration) in
            sessionConfiguration.HTTPAdditionalHeaders = [
                "Authorization": "Bearer \(accessToken)",
                "User-Agent": configuration.userAgent
            ]
        }

        self.configuration = configuration
        self.spaceIdentifier = spaceIdentifier
    }

    private func fetch<T: Decodable>(url: NSURL?, _ completion: Result<T> -> Void) -> NSURLSessionDataTask? {

        let fetchSpaceCompletion: (Result<NSData>) -> () = { result in
            self.fetchSpace() { resultForSpace in
                switch resultForSpace {
                case .Success:
                    guard let data = result.value else { return }
                    self.handleJSON(data, completion)
                case .Error(let error):
                    completion(.Error(error))
                }
            }
        }

        let fetchCompletion: (Result<NSData>) -> () = { result in
            switch result {
            case .Success(let fetchedDecodableData):
                if T.self == Space.self {
                    self.handleJSON(fetchedDecodableData, completion)
                } else {
                    fetchSpaceCompletion(result)
                }
            case .Error(let error):
                completion(.Error(error))
            }
        }

        if let url = url {
            let task = network.fetch(url, completion: fetchCompletion)

            return task
        }

        completion(.Error(Error.InvalidURL(string: "")))
        return nil
    }

    private func handleJSON<T: Decodable>(data: NSData, _ completion: Result<T> -> Void) {
        do {
            let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
            if let json = json as? NSDictionary { json.client = self }

            if let error = try? ContentfulError.decode(json) {
                completion(.Error(error))
                return
            }

            completion(.Success(try T.decode(json)))
        } catch let error as DecodingError {
            completion(.Error(Error.UnparseableJSON(data: data, errorMessage: "\(error)")))
        } catch _ {
            completion(.Error(Error.UnparseableJSON(data: data, errorMessage: "")))
        }
    }

    private func URLForFragment(fragment: String = "", parameters: [String: AnyObject]? = nil) -> NSURL? {
        if let components = NSURLComponents(string: "\(scheme)://\(server)/spaces/\(spaceIdentifier)/\(fragment)") {
            if let parameters = parameters {
                let queryItems: [NSURLQueryItem] = parameters.map() { (key, value) in
                    var value = value

                    if let date = value as? NSDate, dateString = date.toISO8601GMTString() {
                        value = dateString
                    }

                    if let array = value as? NSArray {
                        value = array.componentsJoinedByString(",")
                    }

                    return NSURLQueryItem(name: key, value: value.description)
                }

                if queryItems.count > 0 {
                    components.queryItems = queryItems
                }
            }

            if let url = components.URL {
                return url
            }
        }
        
        return nil
    }
}

extension Client {
    /**
     Fetch a single Asset from Contentful

     - parameter identifier: The identifier of the Asset to be fetched
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchAsset(identifier: String, completion: Result<Asset> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("assets/\(identifier)"), completion)
    }

    /**
     Fetch a collection of Assets from Contentful

     - parameter matching:   Optional list of search parameters the Assets must match
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchAssets(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<Array<Asset>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("assets", parameters: matching), completion)
    }
}

extension Client {
    /**
     Fetch a single Content Type from Contentful

     - parameter identifier: The identifier of the Content Type to be fetched
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchContentType(identifier: String, completion: Result<ContentType> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("content_types/\(identifier)"), completion)
    }

    /**
     Fetch a collection of Content Types from Contentful

     - parameter matching:   Optional list of search parameters the Content Types must match
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchContentTypes(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<Array<ContentType>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("content_types", parameters: matching), completion)
    }
}

extension Client {
    /**
     Fetch a collection of Entries from Contentful

     - parameter matching:   Optional list of search parameters the Entries must match
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchEntries(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<Array<Entry>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("entries", parameters: matching), completion)
    }

    /**
     Fetch a single Entry from Contentful

     - parameter identifier: The identifier of the Entry to be fetched
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchEntry(identifier: String, completion: Result<Entry> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("entries/\(identifier)"), completion)
    }
}

extension Client {
    /**
     Fetch the space this client is constrained to

     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, which enables cancellation of requests, or `nil` if the
        Space was already cached locally
     */
    public func fetchSpace(completion: Result<Space> -> Void) -> NSURLSessionDataTask? {
        if let space = self.space {
            completion(.Success(space))
            return nil
        }
        return fetch(URLForFragment(), completion)
    }
}

extension Client {
    /**
     Perform an initial synchronization of the Space this client is constrained to.

     - parameter matching:   Additional options for the synchronization
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func initialSync(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<SyncSpace> -> Void) -> NSURLSessionDataTask? {
        var parameters = matching
        parameters["initial"] = true
        return sync(parameters, completion: completion)
    }

    func sync(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<SyncSpace> -> Void) -> NSURLSessionDataTask? {
        if configuration.previewMode {
            completion(Result.Error(Error.PreviewAPIDoesNotSupportSync()))
            return nil
        }

        return fetch(URLForFragment("sync", parameters: matching)) { (result: Result<SyncSpace>) in
            if let syncSpace = result.value {
                syncSpace.client = self

                if syncSpace.hasMorePages {
                    var parameters = matching
                    parameters.removeValueForKey("initial")
                    syncSpace.sync(parameters, completion: completion)
                } else {
                    completion(Result.Success(syncSpace))
                }
            } else {
                completion(result)
            }
        }
    }
}
