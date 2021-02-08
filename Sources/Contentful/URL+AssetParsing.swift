//
//  URL+AssetParsing.swift
//  Contentful_iOS
//
//  Created by Marius Kurgonas on 08/02/2021.
//  Copyright © 2021 Contentful GmbH. All rights reserved.
//

import Foundation

extension URL {

    func replacingBaseAssetHostNameWith(hostName: String)throws -> URL {

        guard  URL(string: hostName) != nil else {
            throw SDKError.invalidURL(string: "Asset host base url override is an invalid url: \(hostName)")
        }

        if let urlComponents = NSURLComponents(url: self, resolvingAgainstBaseURL: true),
            let currentHostName = urlComponents.host {
            let components = currentHostName.components(separatedBy: ".")
            guard !components.isEmpty else {
                return self
            }
            var overrideComponents = hostName.components(separatedBy: ".")

            // guard for potential for the url to have a www before asset type name
            if components[0] == "www", components.count >= 2 {
                overrideComponents.insert(components[0], at: 0) // insert www at front
                overrideComponents.insert(components[1], at: 1) // insert asset type subdomain after that
            }
            else {
                overrideComponents.insert(components[0], at: 0) // Just prepend asset type subdomain to the host override
            }

            // Reassemble override base url prepended by the asset type subdomain
            let fullHostOverride = overrideComponents.joined(separator: ".")
            urlComponents.host = fullHostOverride

            // Check if it is a valid url in the end
            guard let overrideUrl = urlComponents.url else {
                return self
            }

            return overrideUrl
        }

        return self
    }
}
