//
//  Client.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Decodable
import Foundation
import Interstellar
import SwiftDate


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
            sessionConfiguration.httpAdditionalHeaders = [ "Authorization": "Bearer \(accessToken)" ]
        }
        
        self.configuration = configuration
        self.spaceIdentifier = spaceIdentifier
    }
    
    private func fetch<T: Decodable>(_ url: URL?, _ completion: (Result<T>) -> Void) -> URLSessionDataTask? {
        if let url = url {
            let (task, signal) = network.fetch(url)
            
            if T.self == Space.self {
                _ = signal
                    .next { self.handleJSON($0 as Data, completion) }
                    .error { completion(.Error($0)) }
            } else {
                _ = fetchSpace().1
                    .next { _ in
                        _ = signal
                            .next { self.handleJSON($0 as Data, completion) }
                            .error { completion(.Error($0)) }
                    }
                    .error { completion(.Error($0)) }
            }
            
            return task
        }
        
        completion(.Error(Error.invalidURL(string: "")))
        return nil
    }
    
    private func handleJSON<T: Decodable>(_ data: Data, _ completion: (Result<T>) -> Void) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let json = json as? NSDictionary { json.client = self }
            
            if let error = try? ContentfulError.decode(json) {
                completion(.Error(error))
                return
            }
            
            completion(.Success(try T.decode(json)))
        } catch let error as DecodingError {
            completion(.Error(Error.unparseableJSON(data: data, errorMessage: "\(error)")))
        } catch _ {
            completion(.Error(Error.unparseableJSON(data: data, errorMessage: "")))
        }
    }
    
    private func URLForFragment(_ fragment: String = "", parameters: [String: AnyObject]? = nil) -> URL? {
        if var components = URLComponents(string: "\(scheme)://\(server)/spaces/\(spaceIdentifier)/\(fragment)") {
            if let parameters = parameters {
                let queryItems: [URLQueryItem] = parameters.map() { (key, value) in
                    var value = value
                    
                    if let date = value as? NSDate, let dateString = date.string(format: .iso8601(options: [.withInternetDateTime])) {
                        value = dateString
                    }
                    
                    if let array = value as? NSArray {
                        value = array.componentsJoined(by: ",")
                    }
                    
                    return URLQueryItem(name: key, value: value.description)
                }
                
                if queryItems.count > 0 {
                    components.queryItems = queryItems
                }
            }
            
            if let url = components.url {
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
    public func fetchAsset(_ identifier: String, completion: (Result<Asset>) -> Void) -> URLSessionDataTask? {
        return fetch(URLForFragment("assets/\(identifier)"), completion)
    }
    
    /**
     Fetch a single Asset from Contentful
     
     - parameter identifier: The identifier of the Asset to be fetched
     
     - returns: A tuple of data task and a signal for the resulting Asset
     */
    public func fetchAsset(_ identifier: String) -> (URLSessionDataTask?, Signal<Asset>) {
        return signalify(identifier, fetchAsset)
    }
    
    /**
     Fetch a collection of Assets from Contentful
     
     - parameter matching:   Optional list of search parameters the Assets must match
     - parameter completion: A handler being called on completion of the request
     
     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchAssets(_ matching: [String:AnyObject] = [String:AnyObject](), completion: (Result<Array<Asset>>) -> Void) -> URLSessionDataTask? {
        return fetch(URLForFragment("assets", parameters: matching), completion)
    }
    
    /**
     Fetch a collection of Assets from Contentful
     
     - parameter matching: Optional list of search parameters the Assets must match
     
     - returns: A tuple of data task and a signal for the resulting array of Assets
     */
    public func fetchAssets(_ matching: [String:AnyObject] = [String:AnyObject]()) -> (URLSessionDataTask?, Signal<Array<Asset>>) {
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
    public func fetchContentType(_ identifier: String, completion: (Result<ContentType>) -> Void) -> URLSessionDataTask? {
        return fetch(URLForFragment("content_types/\(identifier)"), completion)
    }
    
    /**
     Fetch a single Content Type from Contentful
     
     - parameter identifier: The identifier of the Content Type to be fetched
     
     - returns: A tuple of data task and a signal for the resulting Content Type
     */
    public func fetchContentType(_ identifier: String) -> (URLSessionDataTask?, Signal<ContentType>) {
        return signalify(identifier, fetchContentType)
    }
    
    /**
     Fetch a collection of Content Types from Contentful
     
     - parameter matching:   Optional list of search parameters the Content Types must match
     - parameter completion: A handler being called on completion of the request
     
     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchContentTypes(_ matching: [String:AnyObject] = [String:AnyObject](), completion: (Result<Array<ContentType>>) -> Void) -> URLSessionDataTask? {
        return fetch(URLForFragment("content_types", parameters: matching), completion)
    }
    
    /**
     Fetch a collection of Content Types from Contentful
     
     - parameter matching: Optional list of search parameters the Content Types must match
     
     - returns: A tuple of data task and a signal for the resulting array of Content Types
     */
    public func fetchContentTypes(_ matching: [String:AnyObject] = [String:AnyObject]()) -> (URLSessionDataTask?, Signal<Array<ContentType>>) {
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
    public func fetchEntries(_ matching: [String:AnyObject] = [String:AnyObject](), completion: (Result<Array<Entry>>) -> Void) -> URLSessionDataTask? {
        return fetch(URLForFragment("entries", parameters: matching), completion)
    }
    
    /**
     Fetch a collection of Entries from Contentful
     
     - parameter matching: Optional list of search parameters the Entries must match
     
     - returns: A tuple of data task and a signal for the resulting array of Entries
     */
    public func fetchEntries(_ matching: [String:AnyObject] = [String:AnyObject]()) -> (URLSessionDataTask?, Signal<Array<Entry>>) {
        return signalify(matching, fetchEntries)
    }
    
    /**
     Fetch a single Entry from Contentful
     
     - parameter identifier: The identifier of the Entry to be fetched
     - parameter completion: A handler being called on completion of the request
     
     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchEntry(_ identifier: String, completion: (Result<Entry>) -> Void) -> URLSessionDataTask? {
        return fetch(URLForFragment("entries/\(identifier)"), completion)
    }
    
    /**
     Fetch a single Entry from Contentful
     
     - parameter identifier: The identifier of the Entry to be fetched
     
     - returns: A tuple of data task and a signal for the resulting Entry
     */
    public func fetchEntry(_ identifier: String) -> (URLSessionDataTask?, Signal<Entry>) {
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
    public func fetchSpace(_ completion: (Result<Space>) -> Void) -> URLSessionDataTask? {
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
    public func fetchSpace() -> (URLSessionDataTask?, Signal<Space>) {
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
    public func initialSync(_ matching: [String:AnyObject] = [String:AnyObject](), completion: (Result<SyncSpace>) -> Void) -> URLSessionDataTask? {
        var parameters = matching
        parameters["initial"] = true
        return sync(parameters, completion: completion)
    }
    
    /**
     Perform an initial synchronization of the Space this client is constrained to.
     
     - parameter matching: Additional options for the synchronization
     
     - returns: A tuple of data task and a signal for the resulting SyncSpace
     */
    public func initialSync(_ matching: [String:AnyObject] = [String:AnyObject]()) -> (URLSessionDataTask?, Signal<SyncSpace>) {
        return signalify(matching, initialSync)
    }
    
    func sync(_ matching: [String:AnyObject] = [String:AnyObject](), completion: (Result<SyncSpace>) -> Void) -> URLSessionDataTask? {
        if configuration.previewMode {
            completion(.Error(Error.previewAPIDoesNotSupportSync()))
            return nil
        }
        
        return fetch(URLForFragment("sync", parameters: matching), { (result: Result<SyncSpace>) in
            if let value = result.value {
                value.client = self
                
                if value.nextPage {
                    var parameters = matching
                    parameters.removeValue(forKey: "initial")
                    _ = value.sync(parameters, completion: completion)
                } else {
                    completion(.Success(value))
                }
            } else {
                completion(result)
            }
        })
    }
    
    func sync(_ matching: [String:AnyObject] = [String:AnyObject]()) -> (URLSessionDataTask?, Signal<SyncSpace>) {
        return signalify(matching, sync)
    }
}
