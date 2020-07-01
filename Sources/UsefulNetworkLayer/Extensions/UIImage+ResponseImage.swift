//
//  UIImage+ResponseImage.swift
//  MyPet
//
//  Created by Burak Uzunboy on 23.05.20.
//  Copyright © 2020 BUZ. All rights reserved.
//

#if !os(macOS)
import UIKit

/**
 Extends UIImage with Network Layer compatible `ResponseImage` class. With that, image class can directly respond to URLs.
 */
public extension UIImage {
    
    /// Returns immediately if image is available on the cache, otherwise requests from Network Layer and calls completion block.
    @discardableResult
    class func fromURL(_ url: URL, completion: @escaping (_ image: UIImage?)->()) -> UIImage? {
        let api = APIConfiguration(url: url, responseBodyObject: ResponseImage.self, cachingTime: NetworkLayer.CachingTime(seconds: 60*60*24))
        
        api.request { (result) in
            switch result {
            case .failure(_):
                completion(nil)
            case .success(let response):
                completion(response.responseBody?.image)
            }
        }
        
        if let img = UIImage.fromCache(url) {
            return img
        }
        return nil
    }
    
    /// Returns immediately the image if it is available on the cache.
    class func fromCache(_ url: URL) -> UIImage? {
        let api = APIConfiguration(url: url, responseBodyObject: ResponseImage.self)
        guard let response = NetworkLayer.cache?.cachedResponse(for: URLRequest(url: api.requestURL)) else { return nil }
        return UIImage(data: response.data)
    }
    
    /// Downloads image and saves to the cache for future uses.
    class func download(_ url: URL) {
        let api = APIConfiguration(url: url, responseBodyObject: ResponseImage.self, priority: .veryLow, isMainOperation: false)
        api.request { (_) in }
    }
    
}

#endif
