//
//  Metadata.swift
//  Contentful
//
//  Created by Marius Kurgonas on 3/23/21.
//  Copyright © 2021 Contentful GmbH. All rights reserved.
//

import Foundation

/// A representation of metadata that could come as part of an Entry or Asset response.
/// For now it can only contain links to tags
public struct Metadata: Codable {
    
    /// Links to the tags added to an Entry or Asset
    public let tags: [Link]
    
    /// The JSON keys for a `Metadata` instance.
    public enum CodingKeys: String, CodingKey {
        /// The JSON keys for a Metadata object.
        case tags
    }
}
