//
//  Location.swift
//  Contentful
//
//  Created by JP Wright on 22/11/18.
//  Copyright © 2018 Contentful GmbH. All rights reserved.
//

import Foundation

/// Small class to store location coordinates. This is used in preferences over CoreLocation types to avoid
/// extra linking requirements for the SDK.
@objc
public class Location: NSObject, Decodable, NSCoding {

    /// The latitude of this location coordinate.
    public let latitude: Double

    /// The longitude of this location coordinate.
    public let longitude: Double

    /// Initializer for a location object.
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    // MARK: Decodable

    public required init(from decoder: Decoder) throws {
        let container   = try decoder.container(keyedBy: CodingKeys.self)
        latitude        = try container.decode(Double.self, forKey: .latitude)
        longitude       = try container.decode(Double.self, forKey: .longitude)
    }

    private enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lon"
    }

    // MARK: NSCoding

    /// Required initializer for NSCoding conformance.
    @objc
    public required init?(coder aDecoder: NSCoder) {
        self.latitude = aDecoder.decodeDouble(forKey: CodingKeys.latitude.rawValue)
        self.longitude = aDecoder.decodeDouble(forKey: CodingKeys.longitude.rawValue)
    }

    /// Required encoding function for NSCoding conformance.
    @objc
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(latitude, forKey: CodingKeys.latitude.rawValue)
        aCoder.encode(longitude, forKey: CodingKeys.longitude.rawValue)
    }
}
