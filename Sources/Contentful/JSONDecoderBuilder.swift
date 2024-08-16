//
//  Contentful
//
//  Created by Tomasz Szulc on 26/09/2020.
//  Copyright © 2020 Contentful GmbH. All rights reserved.
//

import Foundation

final class JSONDecoderBuilder {
    var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .custom(Date.variableISO8601Strategy)
    var localizationContext: LocalizationContext?
    var timeZone: TimeZone?
    var contentTypes = [ContentTypeId: EntryDecodable.Type]()

    func build() -> JSONDecoder {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = dateDecodingStrategy
        jsonDecoder.userInfo[.localizationContextKey] = localizationContext
        jsonDecoder.userInfo[.timeZoneContextKey] = timeZone
        jsonDecoder.userInfo[.contentTypesContextKey] = contentTypes
        jsonDecoder.userInfo[.linkResolverContextKey] = LinkResolver()
        return jsonDecoder
    }
}
