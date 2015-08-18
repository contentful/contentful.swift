//
//  Asset.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

public class Asset : Resource {
    var scheme = "https"

    public var fields: NSDictionary { return json["fields"] as! NSDictionary }

    public var URL: NSURL {
        
        let urlString = self.fields["file"]?["url"] as! String
        return NSURL(string: "\(scheme):\(urlString)")!
    }
}
