//
//  Contentful
//
//  Created by Tomasz Szulc on 26/09/2020.
//  Copyright © 2020 Contentful GmbH. All rights reserved.
//

import Foundation

extension Client {
    /**
     Performs a synchronization operation, updating the passed in `SyncSpace` instance with latest content from the server.

     If passed in `SyncSpace` is an instance with empty sync token, full synchronization will be done.

     Calling this will mutate passed in `SyncSpace `and also pass back  a reference to it in the completion handler
     in order to allow chaining of operations.

     - Parameters:
         - syncSpace: Instance to perform subsequent sync on. Empty instance by default.
         - syncableTypes: The types that can be synchronized.
         - completion: The completion handler to call when the operation is complete.
      */
    @discardableResult
    public func sync(
        for syncSpace: SyncSpace = SyncSpace(),
        syncableTypes: SyncSpace.SyncableTypes = .all,
        then completion: @escaping ResultsHandler<SyncSpace>
    ) -> URLSessionDataTask? {
        // Preview mode only supports `initialSync` not `nextSync`. The only reason `nextSync` should
        // be called while in preview mode, is internally by the SDK to finish a multiple page sync.
        // We are doing a multi page sync only when syncSpace.hasMorePages is true.
        guard !(host == Host.preview && !syncSpace.syncToken.isEmpty && !syncSpace.hasMorePages) else {
            completion(.failure(SDKError.previewAPIDoesNotSupportSync))
            return nil
        }

        // Send only sync space parameters when accessing another page.
        let parameters = syncSpace.hasMorePages
            ? syncSpace.parameters
            : (syncableTypes.parameters + syncSpace.parameters)

        return fetchDecodable(url: url(endpoint: .sync, parameters: parameters)) { (result: Result<SyncSpace, Error>) in
            switch result {
            case let .success(newSyncSpace):
                syncSpace.updateWithDiffs(from: newSyncSpace)

                // Continue syncing if there are more pages
                guard newSyncSpace.hasMorePages else {
                    self.handleContentTypeFetch(for: syncSpace, completion: completion)
                    return
                }

                // Recursive call to continue syncing
                self.sync(for: syncSpace, syncableTypes: syncableTypes, then: completion)

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func handleContentTypeFetch(
        for syncSpace: SyncSpace,
        completion: @escaping ResultsHandler<SyncSpace>
    ) {
        _ = self.fetchContentTypes { result in
            switch result {
            case let .success(contentTypes):
                for entry in syncSpace.entries {
                    // Assign content type to each entry in the sync space
                    entry.type = contentTypes.first { contentType in
                        contentType.sys.id == entry.sys.contentTypeId
                    }
                }

                self.persistenceIntegration?.update(with: syncSpace)
                completion(.success(syncSpace))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }

    private func fetchContentTypes(
        completion: @escaping ResultsHandler<[ContentType]>
    ) -> URLSessionDataTask {
        return fetchDecodable(url: url(endpoint: .contentTypes)) { (result: Result<HomogeneousArrayResponse<Contentful.ContentType>, Error>) in
            switch result {
            case let .success(contents):
                completion(.success(contents.items))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
