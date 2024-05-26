//
//  CachedResponse.swift
//  better_player
//
//  Created by Amr Saied on 26/05/2024.
//

import Foundation
class CachedResponse: NSObject, NSCoding {
    let data: Data?
    let urlResponse: URLResponse?
    let errorDescription: String?
    
    init(data: Data?, urlResponse: URLResponse?, errorDescription: String?) {
        self.data = data
        self.urlResponse = urlResponse
        self.errorDescription = errorDescription
    }
    
    required init?(coder: NSCoder) {
        self.data = coder.decodeObject(forKey: "data") as? Data
        self.urlResponse = coder.decodeObject(forKey: "urlResponse") as? URLResponse
        self.errorDescription = coder.decodeObject(forKey: "errorDescription") as? String
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(data, forKey: "data")
        coder.encode(urlResponse, forKey: "urlResponse")
        coder.encode(errorDescription, forKey: "errorDescription")
    }
}
