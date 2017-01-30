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

/// Client object for performing requests against the Contentful API
open class Client {
    fileprivate let configuration: Configuration
    fileprivate let network = Network()
    fileprivate let spaceIdentifier: String

    fileprivate var server: String {
        if configuration.previewMode && configuration.server == DEFAULT_SERVER {
            return "preview.contentful.com"
        }
        return configuration.server
    }

    fileprivate(set) var space: Space?

    fileprivate var scheme: String { return configuration.secure ? "https" : "http" }

    /**
     Initializes a new Contentful client instance

     - parameter spaceIdentifier: The space you want to perform requests against
     - parameter accessToken:     The access token used for authorization
     - parameter configuration:   Custom configuration of the client

     - returns: An initialized client instance
     */
    public init(spaceIdentifier: String, accessToken: String, configuration: Configuration = Configuration()) {
        network.sessionConfigurator = { (sessionConfiguration) in
            sessionConfiguration.httpAdditionalHeaders = [
                "Authorization": "Bearer \(accessToken)",
                "User-Agent": configuration.userAgent
            ]
        }

        self.configuration = configuration
        self.spaceIdentifier = spaceIdentifier
    }

    fileprivate func fetch<T: Decodable>(url: URL?, completion: @escaping (Result<T>) -> Void) -> URLSessionDataTask? {
        if let url = url {
            let (task, signal) = network.fetch(url: url)

            if T.self == Space.self {
                signal
                    .then { self.handleJSON($0, completion) }
                    .error { completion(.error($0)) }
            } else {
                fetchSpace().1
                    .then { _ in
                        signal
                            .then { self.handleJSON($0, completion) }
                            .error { completion(.error($0)) }
                    }
                    .error { completion(.error($0)) }
            }

            return task
        }

        completion(.error(SDKError.invalidURL(string: "")))
        return nil
    }

    fileprivate func handleJSON<T: Decodable>(_ data: Data, _ completion: (Result<T>) -> Void) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let json = json as? NSDictionary { json.client = self }

            if let error = try? ContentfulError.decode(json) {
                completion(.error(error))
                return
            }

            completion(.success(try T.decode(json)))
        } catch let error as DecodingError {
            completion(.error(SDKError.unparseableJSON(data: data, errorMessage: "\(error)")))
        } catch _ {
            completion(.error(SDKError.unparseableJSON(data: data, errorMessage: "")))
        }
    }

    fileprivate func URLForFragment(fragment: String = "", parameters: [String: Any]? = nil) -> URL? {
        if var components = URLComponents(string: "\(scheme)://\(server)/spaces/\(spaceIdentifier)/\(fragment)") {
            if let parameters = parameters {
                let queryItems: [URLQueryItem] = parameters.map() { (key, value) in
                    var value = value

                    if let date = value as? Date, let dateString = date.toISO8601GMTString() {
                        value = dateString
                    }

                    // FIXME: Should this be an NSArray?
                    if let array = value as? NSArray {
                        value = array.componentsJoined(by: ",")
                    }

                    return URLQueryItem(name: key, value: (value as AnyObject).description)
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
    @discardableResult public func fetchAsset(identifier: String, completion: @escaping (Result<Asset>) -> Void) -> URLSessionDataTask? {
        return fetch(url: URLForFragment(fragment: "assets/\(identifier)"), completion: completion)
    }

    /**
     Fetch a single Asset from Contentful

     - parameter identifier: The identifier of the Asset to be fetched

     - returns: A tuple of data task and a signal for the resulting Asset
     */
    @discardableResult public func fetchAsset(identifier: String) -> (URLSessionDataTask?, Observable<Result<Asset>>) {
        let closure: SignalObservation<String, Asset> = fetchAsset(identifier:completion:)
        return signalify(parameter: identifier, closure: closure)
    }

    /**
     Fetch a collection of Assets from Contentful

     - parameter matching:   Optional list of search parameters the Assets must match
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    @discardableResult public func fetchAssets(matching: [String : Any] = [:], completion: @escaping (Result<Array<Asset>>) -> Void) -> URLSessionDataTask? {
        return fetch(url: URLForFragment(fragment: "assets", parameters: matching), completion: completion)
    }

    /**
     Fetch a collection of Assets from Contentful

     - parameter matching: Optional list of search parameters the Assets must match

     - returns: A tuple of data task and a signal for the resulting array of Assets
     */
    @discardableResult public func fetchAssets(matching: [String : Any] = [:]) -> (URLSessionDataTask?, Observable<Result<Array<Asset>>>) {
        let closure: SignalObservation<[String : Any], Array<Asset>> = fetchAssets(matching:completion:)
        return signalify(parameter: matching, closure: closure)
    }
}

extension Client {
    /**
     Fetch a single Content Type from Contentful

     - parameter identifier: The identifier of the Content Type to be fetched
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    @discardableResult public func fetchContentType(identifier: String, completion: @escaping (Result<ContentType>) -> Void) -> URLSessionDataTask? {
        return fetch(url: URLForFragment(fragment: "content_types/\(identifier)"), completion: completion)
    }

    /**
     Fetch a single Content Type from Contentful

     - parameter identifier: The identifier of the Content Type to be fetched

     - returns: A tuple of data task and a signal for the resulting Content Type
     */
    @discardableResult public func fetchContentType(identifier: String) -> (URLSessionDataTask?, Observable<Result<ContentType>>) {
        let closure: SignalObservation<String, ContentType> = fetchContentType(identifier:completion:)
        return signalify(parameter: identifier, closure: closure)
    }

    /**
     Fetch a collection of Content Types from Contentful

     - parameter matching:   Optional list of search parameters the Content Types must match
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    @discardableResult public func fetchContentTypes(matching: [String:Any] = [:], completion: @escaping (Result<Array<ContentType>>) -> Void) -> URLSessionDataTask? {
        return fetch(url: URLForFragment(fragment: "content_types", parameters: matching), completion: completion)
    }

    /**
     Fetch a collection of Content Types from Contentful

     - parameter matching: Optional list of search parameters the Content Types must match

     - returns: A tuple of data task and a signal for the resulting array of Content Types
     */
    @discardableResult public func fetchContentTypes(matching: [String : Any] = [:]) -> (URLSessionDataTask?, Observable<Result<Array<ContentType>>>) {
        let closure: SignalObservation<[String : Any], Array<ContentType>> = fetchContentTypes(matching:completion:)
        return signalify(parameter: matching, closure: closure)
    }
}

extension Client {
    /**
     Fetch a collection of Entries from Contentful

     - parameter matching:   Optional list of search parameters the Entries must match
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    @discardableResult public func fetchEntries(matching: [String : Any] = [:], completion: @escaping (Result<Array<Entry>>) -> Void) -> URLSessionDataTask? {
        return fetch(url: URLForFragment(fragment: "entries", parameters: matching), completion: completion)
    }

    /**
     Fetch a collection of Entries from Contentful

     - parameter matching: Optional list of search parameters the Entries must match

     - returns: A tuple of data task and a signal for the resulting array of Entries
     */
    @discardableResult public func fetchEntries(matching: [String : Any] = [:]) -> (URLSessionDataTask?, Observable<Result<Array<Entry>>>) {
        let closure: SignalObservation<[String : Any], Array<Entry>> = fetchEntries(matching:completion:)
        return signalify(parameter: matching, closure: closure)
    }

    /**
     Fetch a single Entry from Contentful

     - parameter identifier: The identifier of the Entry to be fetched
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    @discardableResult public func fetchEntry(identifier: String, completion: @escaping (Result<Entry>) -> Void) -> URLSessionDataTask? {
        return fetch(url: URLForFragment(fragment: "entries/\(identifier)"), completion: completion)
    }

    /**
     Fetch a single Entry from Contentful

     - parameter identifier: The identifier of the Entry to be fetched

     - returns: A tuple of data task and a signal for the resulting Entry
     */
    @discardableResult public func fetchEntry(identifier: String) -> (URLSessionDataTask?, Observable<Result<Entry>>) {
        let closure: SignalObservation<String, Entry> = fetchEntry(identifier:completion:)
        return signalify(parameter: identifier, closure: closure)
    }
}

extension Client {
    /**
     Fetch the space this client is constrained to

     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, which enables cancellation of requests, or `nil` if the
        Space was already cached locally
     */
    @discardableResult public func fetchSpace(completion: @escaping (Result<Space>) -> Void) -> URLSessionDataTask? {
        if let space = self.space {
            completion(.success(space))
            return nil
        }
        return fetch(url: URLForFragment(), completion: completion)
    }

    /**
     Fetch the space this client is constrained to

     - returns: A tuple of data task and a signal for the resulting Space
     */
    @discardableResult public func fetchSpace() -> (URLSessionDataTask?, Observable<Result<Space>>) {
        let closure: SignalBang<Space> = fetchSpace(completion:)
        return signalify(closure: closure)
    }
}

extension Client {
    /**
     Perform an initial synchronization of the Space this client is constrained to.

     - parameter matching:   Additional options for the synchronization
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    @discardableResult public func initialSync(matching: [String : Any] = [:], completion: @escaping (Result<SyncSpace>) -> Void) -> URLSessionDataTask? {
        var parameters = matching
        parameters["initial"] = true
        return sync(matching: parameters, completion: completion)
    }

    /**
     Perform an initial synchronization of the Space this client is constrained to.

     - parameter matching: Additional options for the synchronization

     - returns: A tuple of data task and a signal for the resulting SyncSpace
     */
    @discardableResult public func initialSync(matching: [String : Any] = [:]) -> (URLSessionDataTask?, Observable<Result<SyncSpace>>) {
        let closure: SignalObservation<[String : Any], SyncSpace> = initialSync(matching:completion:)
        return signalify(parameter: matching, closure: closure)
    }

    func sync(matching: [String : Any] = [:], completion: @escaping (Result<SyncSpace>) -> Void) -> URLSessionDataTask? {
        if configuration.previewMode {
            completion(.error(SDKError.previewAPIDoesNotSupportSync()))
            return nil
        }

        return fetch(url: URLForFragment(fragment: "sync", parameters: matching), completion: { (result: Result<SyncSpace>) in
            if let value = result.value {
                value.client = self

                if value.nextPage {
                    var parameters = matching
                    parameters.removeValue(forKey: "initial")
                    value.sync(matching: parameters, completion: completion)
                } else {
                    completion(.success(value))
                }
            } else {
                completion(result)
            }
        })
    }

    func sync(matching: [String : Any] = [:]) -> (URLSessionDataTask?, Observable<Result<SyncSpace>>) {
        let closure: SignalObservation<[String : Any], SyncSpace> = sync(matching:completion:)
        return signalify(parameter: matching, closure: closure)
    }
}
