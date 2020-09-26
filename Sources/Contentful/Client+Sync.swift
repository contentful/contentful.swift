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
        - syncSpace: Instance to perform subsqeuent sync on. Empty instance by default.
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
        if !syncSpace.syncToken.isEmpty && host == Host.preview && syncSpace.hasMorePages == false {
            completion(.failure(SDKError.previewAPIDoesNotSupportSync))
            return nil
        }

        // Send only sync space parameters when accessing another page.
        let parameters: [String: String]
        if syncSpace.hasMorePages {
            parameters = syncSpace.parameters
        } else {
            parameters = syncableTypes.parameters + syncSpace.parameters
        }

        return fetchDecodable(url: url(endpoint: .sync, parameters: parameters)) { (result: Result<SyncSpace, Error>) in
            switch result {
            case .success(let newSyncSpace):
                syncSpace.updateWithDiffs(from: newSyncSpace)
                self.persistenceIntegration?.update(with: newSyncSpace)
                if newSyncSpace.hasMorePages {
                    self.sync(for: syncSpace, syncableTypes: syncableTypes, then: completion)
                } else {
                    completion(.success(syncSpace))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
