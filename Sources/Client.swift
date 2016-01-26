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
            sessionConfiguration.HTTPAdditionalHeaders = [ "Authorization": "Bearer \(accessToken)" ]
        }

        self.configuration = configuration
        self.spaceIdentifier = spaceIdentifier
    }

    private func fetch<T: Decodable>(url: NSURL?, _ completion: Result<T> -> Void) -> NSURLSessionDataTask? {
        if let url = url {
            let (task, signal) = network.fetch(url)

            if T.self == Space.self {
                signal
                    .next { self.handleJSON($0, completion) }
                    .error { completion(.Error($0)) }
            } else {
                fetchSpace().1
                    .next { _ in
                        signal
                            .next { self.handleJSON($0, completion) }
                            .error { completion(.Error($0)) }
                    }
                    .error { completion(.Error($0)) }
            }

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
            completion(.Error(Error.UnparseableJSON(data: data, errorMessage: error.debugDescription)))
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
     Fetch a single Asset from Contentful

     - parameter identifier: The identifier of the Asset to be fetched

     - returns: A tuple of data task and a signal for the resulting Asset
     */
    public func fetchAsset(identifier: String) -> (NSURLSessionDataTask?, Signal<Asset>) {
        return signalify(identifier, fetchAsset)
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

    /**
     Fetch a collection of Assets from Contentful

     - parameter matching: Optional list of search parameters the Assets must match

     - returns: A tuple of data task and a signal for the resulting array of Assets
     */
    public func fetchAssets(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<Array<Asset>>) {
        return signalify(matching, fetchAssets)
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
     Fetch a single Content Type from Contentful

     - parameter identifier: The identifier of the Content Type to be fetched

     - returns: A tuple of data task and a signal for the resulting Content Type
     */
    public func fetchContentType(identifier: String) -> (NSURLSessionDataTask?, Signal<ContentType>) {
        return signalify(identifier, fetchContentType)
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

    /**
     Fetch a collection of Content Types from Contentful

     - parameter matching: Optional list of search parameters the Content Types must match

     - returns: A tuple of data task and a signal for the resulting array of Content Types
     */
    public func fetchContentTypes(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<Array<ContentType>>) {
        return signalify(matching, fetchContentTypes)
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
     Fetch a collection of Entries from Contentful

     - parameter matching: Optional list of search parameters the Entries must match

     - returns: A tuple of data task and a signal for the resulting array of Entries
     */
    public func fetchEntries(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<Array<Entry>>) {
        return signalify(matching, fetchEntries)
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

    /**
     Fetch a single Entry from Contentful

     - parameter identifier: The identifier of the Entry to be fetched

     - returns: A tuple of data task and a signal for the resulting Entry
     */
    public func fetchEntry(identifier: String) -> (NSURLSessionDataTask?, Signal<Entry>) {
        return signalify(identifier, fetchEntry)
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

    /**
     Fetch the space this client is constrained to

     - returns: A tuple of data task and a signal for the resulting Space
     */
    public func fetchSpace() -> (NSURLSessionDataTask?, Signal<Space>) {
        return signalify(fetchSpace)
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

    /**
     Perform an initial synchronization of the Space this client is constrained to.

     - parameter matching: Additional options for the synchronization

     - returns: A tuple of data task and a signal for the resulting SyncSpace
     */
    public func initialSync(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<SyncSpace>) {
        return signalify(matching, initialSync)
    }

    func sync(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<SyncSpace> -> Void) -> NSURLSessionDataTask? {
        if configuration.previewMode {
            completion(.Error(Error.PreviewAPIDoesNotSupportSync()))
            return nil
        }

        return fetch(URLForFragment("sync", parameters: matching), { (result: Result<SyncSpace>) in
            if let value = result.value {
                value.client = self

                if value.nextPage {
                    var parameters = matching
                    parameters.removeValueForKey("initial")
                    value.sync(parameters, completion: completion)
                } else {
                    completion(.Success(value))
                }
            } else {
                completion(result)
            }
        })
    }

    func sync(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<SyncSpace>) {
        return signalify(matching, sync)
    }
}
