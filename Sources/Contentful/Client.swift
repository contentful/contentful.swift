//
//  Client.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Foundation

/// The completion callback for an API request with a `Result<T>` containing the requested object of
/// type `T` on success, or an error if the request was unsuccessful.
public typealias ResultsHandler<T> = (_ result: Result<T, Error>) -> Void

/// Client object for performing requests against the Contentful Delivery and Preview APIs.
open class Client {

    /// The configuration for this instance of the client.
    public let clientConfiguration: ClientConfiguration

    /// The identifier of the space this Client is set to interface with.
    public let spaceId: String

    /// The identifier of the environment within the space that this Client is set to interface with.
    public let environmentId: String

    /// Available Locales for this environment
    public var locales: [Contentful.Locale]?

    /// Context for holding information about the fallback chain of locales for the Space.
    public private(set) var localizationContext: LocalizationContext! {
        set { jsonDecoderBuilder.localizationContext = newValue }
        get { jsonDecoderBuilder.localizationContext }
    }

    /// The base domain that all URIs have for each request the client makes.
    public let host: String

    /**
    Builder for `JSONDecoder` instance that is used to deserialize JSONs.

    `Client` will inject information about the locales to the builder and use this information
    to normalize the fields dictionary of entries and assets.
     */
    private let jsonDecoderBuilder = JSONDecoderBuilder()

    // Always returns new instance of the decoder. For legacy code support.
    public var jsonDecoder: JSONDecoder {
        jsonDecoderBuilder.build()
    }

    /// The persistence integration which will receive delegate messages from the `Client` when new
    /// `Entry` and `Asset` objects are created from data being sent over the network. Currently, these
    /// messages are only sent during the response hadling for `client.sync` calls. See a CoreData
    /// persistence integration at <https://github.com/contentful/contentful-persistence.swift>.
    public var persistenceIntegration: PersistenceIntegration? {
        didSet {
            guard var headers = self.urlSession.configuration.httpAdditionalHeaders else {
                assertionFailure("Headers should have already been set on the current URL Session.")
                return
            }
            assert(headers["Authorization"] != nil)
            headers["X-Contentful-User-Agent"] = clientConfiguration.userAgentString(with: persistenceIntegration)

            // There is a bug in foundation with directly setting the headers like so self.urlSession.configuration.header = ...
            // so we must recreate the URLSession in order to set the headers.
            let configuration = self.urlSession.configuration
            configuration.httpAdditionalHeaders = headers
            self.urlSession = URLSession(configuration: configuration)
        }
    }

    internal var urlSession: URLSession

    fileprivate(set) internal var space: Space?

    fileprivate var scheme: String { return clientConfiguration.secure ? "https": "http" }

    /// Initializes a new Contentful client instance
    ///
    /// - Parameters:
    ///   - spaceId: The identifier of the space to perform requests against.
    ///   - environmentId: The identifier of the space environment to perform requests against. Defaults to "master".
    ///   - accessToken: The access token used for authorization.
    ///   - host: The domain host to perform requests against. Defaults to `Host.delivery` i.e. `"cdn.contentful.com"`.
    ///   - clientConfiguration: Custom Configuration of the Client. Uses `ClientConfiguration.default` if omitted.
    ///   - sessionConfiguration: The configuration for the URLSession. Note that HTTP headers will be overwritten
    ///         internally by the SDK so that requests can be authorized correctly.
    ///   - persistenceIntegration: An object conforming to the `PersistenceIntegration` protocol
    ///         which will receive messages about created/deleted Resources when calling `sync` methods.
    ///   - contentTypeClasses: An array of `EntryDecodable` classes to map Contentful entries to when using the relevant fetch methods.
    public init(spaceId: String,
                environmentId: String = "master",
                accessToken: String,
                host: String = Host.delivery,
                clientConfiguration: ClientConfiguration = .default,
                sessionConfiguration: URLSessionConfiguration = .default,
                persistenceIntegration: PersistenceIntegration? = nil,
                contentTypeClasses: [EntryDecodable.Type]? = nil) {

        self.spaceId = spaceId
        self.environmentId = environmentId
        self.host = host
        self.clientConfiguration = clientConfiguration

        if let dateDecodingStrategy = clientConfiguration.dateDecodingStrategy {
            // Override default date decoding strategy if present
            jsonDecoderBuilder.dateDecodingStrategy = dateDecodingStrategy
        }
        if let timeZone = clientConfiguration.timeZone {
            jsonDecoderBuilder.timeZone = timeZone
        }

        if let contentTypeClasses = contentTypeClasses {
            var contentTypes = [ContentTypeId: EntryDecodable.Type]()
            for type in contentTypeClasses {
                contentTypes[type.contentTypeId] = type
            }

            jsonDecoderBuilder.contentTypes = contentTypes
        }

        self.persistenceIntegration = persistenceIntegration
        let contentfulHTTPHeaders = [
            "Authorization": "Bearer \(accessToken)",
            "X-Contentful-User-Agent": clientConfiguration.userAgentString(with: persistenceIntegration)
        ]
        sessionConfiguration.httpAdditionalHeaders = contentfulHTTPHeaders
        self.urlSession = URLSession(configuration: sessionConfiguration)
    }

    deinit {
        urlSession.invalidateAndCancel()
    }

    /// Returns an optional URL for the specified endpoint with its query paramaters.
    ///
    /// - Parameters:
    ///   - endpoint: The delivery/preview API endpoint.
    ///   - parameters: A dictionary of query parameters which be appended at the end of the URL in a URL safe format.
    /// - Returns: A valid URL for the Content Delivery or Preview API, or nil if the URL could not be constructed.
    public func url(endpoint: Endpoint, parameters: [String: String]? = nil) -> URL {
        var components: URLComponents

        switch endpoint {
        case .spaces:
            components = URLComponents(string: "\(scheme)://\(host)/spaces/\(spaceId)/\(endpoint.pathComponent)")!
        case .assets, .contentTypes, .locales, .entries, .sync:
            components = URLComponents(string: "\(scheme)://\(host)/spaces/\(spaceId)/environments/\(environmentId)/\(endpoint.pathComponent)")!
        }

        let queryItems: [URLQueryItem]? = parameters?.map { key, value in
            return URLQueryItem(name: key, value: value)
        }
        // Since Swift 4.2, the order of a dictionary's keys will vary accross executions so we must sort
        // the parameters so that the URL is consistent accross executions (so that all test recordings are found).
        components.queryItems = queryItems?.sorted { a, b in
            return a.name > b.name
        }

        let url = components.url!
        return url
    }

    internal func fetchDecodable<DecodableType: Decodable>(
        url: URL,
        completion: @escaping ResultsHandler<DecodableType>
    ) -> URLSessionDataTask {
        let finishDataFetch: (ResultsHandler<Data>) = { result in
            switch result {
            case .success(let mappableData):
                self.handleJSON(data: mappableData, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }

        let task = fetchData(url: url) { dataResult in
            if url.lastPathComponent == "locales" || url.lastPathComponent == self.spaceId {
                // Now that we have all the locale information, start callback chain.
                finishDataFetch(dataResult)
            } else {
                self.fetchLocalesIfNecessary { localesResult in
                    switch localesResult {
                    case .success:
                        // Trigger chain with data we're currently interested in.
                        finishDataFetch(dataResult)
                    case .failure(let error):
                        // Return the current error.
                        finishDataFetch(.failure(error))
                    }
                }
            }
        }
        return task
    }

    internal func fetchData(url: URL, completion: @escaping ResultsHandler<Data>) -> URLSessionDataTask {
        let jsonDecoder = jsonDecoderBuilder.build()

        let task = urlSession.dataTask(with: url) { data, response, error in
            if let data = data {
                if self.didHandleRateLimitError(
                    data: data,
                    response: response,
                    jsonDecoder: jsonDecoder,
                    completion: completion
                ) == true {
                    return // Exit if there was a RateLimitError.
                }

                // Use failable initializer to optional rather than initializer that throws,
                // because failure to find an error in the JSON should error should not throw an error that JSON is not parseable.
                if let response = response as? HTTPURLResponse {
                    if response.statusCode != 200 {
                        if let apiError = APIError.error(with: jsonDecoder,
                                                         data: data,
                                                         statusCode: response.statusCode) {
                            let errorMessage = """
                            Errored: 'GET' (\(response.statusCode)) \(url.absoluteString)
                            Message: \(apiError.message!)"
                            """
                            ContentfulLogger.log(.error, message: errorMessage)
                            completion(.failure(apiError))
                        } else {
                            // In case there is an error returned by the API that has an unexpected format, return a custom error.
                            let errorMessage = "An API error was returned that the SDK was unable to parse"
                            let logMessage = """
                            Errored: 'GET' \(url.absoluteString). \(errorMessage)
                            Message: \(errorMessage)
                            """
                            ContentfulLogger.log(.error, message: logMessage)
                            let error = SDKError.unparseableJSON(data: data, errorMessage: errorMessage)
                            completion(.failure(error))
                        }
                        return
                    }
                    let successMessage = "Success: 'GET' (\(response.statusCode)) \(url.absoluteString)"
                    ContentfulLogger.log(.info, message: successMessage)
                }
                completion(Result.success(data))
                return
            }

            if let error = error {
                // An extra check, just in case.
                let errorMessage = """
                Errored: 'GET' \(url.absoluteString)
                Message: \(error.localizedDescription)
                """
                ContentfulLogger.log(.error, message: errorMessage)
                completion(.failure(error))
                return
            }

            let sdkError = SDKError.invalidHTTPResponse(response: response)
            let errorMessage = """
            Errored: 'GET' \(url.absoluteString)
            Message: Request returned invalid HTTP response: \(sdkError.localizedDescription)"
            """
            ContentfulLogger.log(.error, message: errorMessage)
            completion(.failure(sdkError))
        }

        let logMessage = "Request: 'GET' \(url.absoluteString)"
        ContentfulLogger.log(.info, message: logMessage)
        task.resume()
        return task
    }

    internal func fetchResource<ResourceType>(
        resourceType: ResourceType.Type,
        id: String,
        include includesLevel: UInt? = nil,
        completion: @escaping ResultsHandler<ResourceType>
    ) -> URLSessionDataTask where ResourceType: Decodable & EndpointAccessible {
        // If the resource is not an entry, includes are not supported.
        if !(resourceType is EntryDecodable.Type) && resourceType != Entry.self {
            var url = self.url(endpoint: ResourceType.endpoint)
            url.appendPathComponent(id)
            return fetchDecodable(
                url: url,
                completion: completion
            )
        }

        // Before `completion` is called, either the first item is extracted, and
        // sent as `.success`, or an `.error` is sent.
        let fetchCompletion: (Result<HomogeneousArrayResponse<ResourceType>, Error>) -> Void = { result in
            switch result {
            case .success(let response):
                guard let firstItem = response.items.first else {
                    completion(.failure(SDKError.noResourceFoundFor(id: id)))
                    break
                }
                completion(.success(firstItem))
            case .failure(let error):
                completion(.failure(error))
            }
        }

        var query = ResourceQuery.where(sys: .id, .equals(id))
        if let includesLevel = includesLevel {
            query = query.include(includesLevel)
        }

        return fetchDecodable(
            url: url(endpoint: ResourceType.endpoint, parameters: query.parameters),
            completion: fetchCompletion
        )
    }

    /// Fetches the space this client is configured to interface with.

    /**
    Fetches the `Space` the client is configured to interface with.

    If there is a space in the cache, it will be returned and no request will be performed.
    Otherwise, the space will be fetched and stored.
     */
    @discardableResult
    internal func fetchCurrentSpace(then completion: @escaping ResultsHandler<Space>) -> URLSessionDataTask? {
        // Attempt to pull from cache first.
        if let space = self.space {
            completion(.success(space))
            return nil
        }

        return fetchDecodable(url: url(endpoint: .spaces)) { (result: Result<Space, Error>) in
            switch result {
            case .success(let space):
                self.space = space
            default:
                break
            }

            completion(result)
        }
    }

    /// Fetches all the locales belonging to the space environment that this client is configured to interface with.
    ///
    /// - Parameters:
    ///   - completion: A handler being called on completion of the request.
    /// - Returns: Returns the `URLSessionDataTask` of the request which can be used for request cancellation.
    @discardableResult
    internal func fetchCurrentSpaceLocales(then completion: @escaping ResultsHandler<HomogeneousArrayResponse<Contentful.Locale>>) -> URLSessionDataTask {

        // The robust thing to do would be to fetch all pages of the `/locales` endpoint, however, pagination is not supported
        // at the moment. We also are not expecting any consumers to have > 1000 locales as Contentful subscriptions do not allow that.
        let query = ResourceQuery.limit(to: QueryConstants.maxLimit)
        let url = self.url(endpoint: .locales, parameters: query.parameters)
        return fetchDecodable(url: url) { (result: Result<HomogeneousArrayResponse<Contentful.Locale>, Error>) in
            switch result {
            case .success(let localesArray):
                let locales = localesArray.items
                self.locales = locales

                let localeCodes = locales.map { $0.code }
                self.persistenceIntegration?.update(localeCodes: localeCodes)

                guard let localizationContext = LocalizationContext(locales: locales) else {
                    let error = SDKError.localeHandlingError(message: "Locale with default == true not found in Environment!")
                    completion(.failure(error))
                    return
                }
                self.localizationContext = localizationContext
                completion(result)

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    @discardableResult
    private func fetchLocalesIfNecessary(then completion: @escaping ResultsHandler<Array<Contentful.Locale>>) -> URLSessionDataTask? {
        if let locales = self.locales {
            let localeCodes = locales.map { $0.code }
            persistenceIntegration?.update(localeCodes: localeCodes)
            completion(Result.success(locales))
            return nil
        }
        return fetchCurrentSpaceLocales { result in
            switch result {
            case .success(let localesResponse):
                completion(Result.success(localesResponse.items))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // Returns the rate limit reset.
    fileprivate func readRateLimitHeaderIfPresent(response: URLResponse?) -> Int? {
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 429 {

                let rateLimitResetPair = httpResponse.allHeaderFields.filter { arg in
                    let (key, _) = arg
                    return (key as? String)?.lowercased() == "x-contentful-ratelimit-reset"
                }
                if let rateLimitResetString = rateLimitResetPair.first?.value as? String {
                    return Int(rateLimitResetString)
                }

            }
        }
        return nil
    }

    // Returns true if a rate limit error was returned by the API.
    fileprivate func didHandleRateLimitError(
        data: Data,
        response: URLResponse?,
        jsonDecoder: JSONDecoder,
        completion: ResultsHandler<Data>
    ) -> Bool {
        guard let timeUntilLimitReset = self.readRateLimitHeaderIfPresent(response: response) else { return false }

        // At this point, We know for sure that the type returned by the API can be mapped to an `APIError` instance.
        // Directly handle JSON and exit.
        let statusCode = (response as! HTTPURLResponse).statusCode
        self.handleRateLimitJSON(
            data: data,
            timeUntilLimitReset: timeUntilLimitReset,
            statusCode: statusCode,
            jsonDecoder: jsonDecoder
        ) { (_ result: Result<RateLimitError, Error>) in
            switch result {
            case .success(let rateLimitError):
                completion(.failure(rateLimitError))
            case .failure(let auxillaryError):
                // We should never get here, but we'll bubble up what should be a `SDKError.unparseableJSON` error just in case.
                completion(.failure(auxillaryError))
            }
        }
        return true
    }

    private func handleRateLimitJSON(
        data: Data,
        timeUntilLimitReset: Int,
        statusCode: Int,
        jsonDecoder: JSONDecoder,
        completion: ResultsHandler<RateLimitError>
    ) {
        guard let rateLimitError = try? jsonDecoder.decode(RateLimitError.self, from: data) else {
            completion(.failure(SDKError.unparseableJSON(data: data, errorMessage: "SDK unable to parse RateLimitError payload")))
            return
        }
        rateLimitError.statusCode = statusCode
        rateLimitError.timeBeforeLimitReset = timeUntilLimitReset

        let errorMessage = """
        Errored: Rate Limit Error
        Message: \(rateLimitError)"
        """
        ContentfulLogger.log(.error, message: errorMessage)
        // In this case, .success means that a RateLimitError was successfully initialized.
        completion(Result.success(rateLimitError))
    }

    private func handleJSON<DecodableType: Decodable>(
        data: Data,
        completion: @escaping ResultsHandler<DecodableType>
    ) {
        let jsonDecoder = jsonDecoderBuilder.build()

        var decodedObject: DecodableType?
        do {
            decodedObject = try jsonDecoder.decode(DecodableType.self, from: data)
        } catch let error {
            let sdkError = SDKError.unparseableJSON(data: data, errorMessage: "\(error)")
            ContentfulLogger.log(.error, message: sdkError.message)
            completion(.failure(sdkError))
        }

        guard let linkResolver = jsonDecoder.userInfo[.linkResolverContextKey] as? LinkResolver else {
            let error = SDKError.unparseableJSON(
                data: data,
                errorMessage: "Couldn't find link resolver instance."
            )
            ContentfulLogger.log(.error, message: error.message)
            completion(.failure(error))
            return
        }

        linkResolver.churnLinks()

        // Make sure decoded object is not nil before calling success completion block.
        if let decodedObject = decodedObject {
            completion(.success(decodedObject))
        } else {
            let error = SDKError.unparseableJSON(
                data: data,
                errorMessage: "Unknown error occured during decoding."
            )
            ContentfulLogger.log(.error, message: error.message)
            completion(.failure(error))
        }
    }
}
