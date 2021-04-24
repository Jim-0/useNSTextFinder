//
//  Content.swift
//  UseTextFinder
//
//  Created by jim on 2021/4/24.
//  Copyright © 2021 Jim. All rights reserved.
//

import Cocoa

class Content: NSObject {
    @objc dynamic var contentString = ""
    
    public init(contentString: String) {
        self.contentString = contentString
    }
    
}

extension Content {
    
    func read(from data: Data) {
        contentString = String(bytes: data, encoding: .utf8)!
    }
    
    func data() -> Data? {
        return contentString.data(using: .utf8)
    }
    
}
