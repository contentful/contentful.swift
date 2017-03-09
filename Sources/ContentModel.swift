//
//  ContentModel.swift
//  Contentful
//
//  Created by JP Wright on 09/03/2017.
//  Copyright © 2017 Contentful GmbH. All rights reserved.
//

import Foundation
import Decodable
import Interstellar


public protocol ContentModel {

    init(fields: [String: Any])
}
