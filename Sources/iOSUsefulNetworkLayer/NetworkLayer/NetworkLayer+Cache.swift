//
//  NetworkLayer+Cache.swift
//  DCA_iOS
//
//  Created by Burak Uzunboy on 01.08.19.
//  Copyright © 2019 Exozet. All rights reserved.
//

import UIKit

extension NetworkLayer {
    
    /// Custom Caching class.
    class Cache: URLCache {
        
        /// Default initializer.
        override init() {
            super.init()
            self.initialize()
        }
        
        /**
         Initialize cache with the specified capacity preferences and path.
         - parameter memoryCapacity: The RAM demand. Set `0` if you don't want to use temporary memory
         - parameter diskCapacity: The storage demand. Set `0` if you don't want to save cache indefinitely
         - parameter diskPath: The path for the custom location in the storage to save
         */
        override init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) {
            super.init(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: path)
            self.initialize()
        }
        
        /// Registers `NotificationCenter` for necessary messages.
        private func initialize() {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(didReceiveMemoryWarning),
                                                   name: UIApplication.didReceiveMemoryWarningNotification,
                                                   object: nil)
        }
        
        /// Remove observer from the `NotificationCenter`
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        /// Checks validity of the cached response with expiry value. Returns `nil` if its not valid.
        private func checkCachedResponse(_ response: CachedURLResponse?) -> CachedURLResponse? {
            guard let endDate = response?.userInfo?["cachingEndsAt"] as? Date else { return response }
            
            if endDate > Date() {
                return response
            } else {
                return nil
            }
        }
        
        /// Updates cache expiry of the specified request
        /// - returns: `true` if timer updated successfuly.
        @discardableResult
        public func changeCacheExpiry(for request: URLRequest, to date: Date) -> Bool {
            if let cachedResponse = self.cachedResponseWithForce(for: request) {
                let userInfo = ["cachingEndsAt": date]
                let newCacheObj = CachedURLResponse(response: cachedResponse.response,
                                                    data: cachedResponse.data,
                                                    userInfo: userInfo,
                                                    storagePolicy: .allowed)
                self.removeCachedResponse(for: request)
                self.storeCachedResponse(newCacheObj, for: request)
                return true
            }
            
            return false
        }
        
        /// Updates cache expiry of the specified request
        /// - returns: `true` if timer updated successfuly.
        @discardableResult
        public func changeCacheExpiry(for task: URLSessionDataTask, to date: Date) -> Bool {
            guard let request = task.currentRequest else { return false }
            if let cachedResponse = self.cachedResponseWithForce(for: request) {
                let userInfo = ["cachingEndsAt": date]
                let newCacheObj = CachedURLResponse(response: cachedResponse.response,
                                                    data: cachedResponse.data,
                                                    userInfo: userInfo,
                                                    storagePolicy: .allowed)
                self.removeCachedResponse(for: task)
                self.storeCachedResponse(newCacheObj, for: task)
                return true
            }
            
            return false
        }
        
        /// Checks the response and acts accordingly.
        override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
            let cachedResponse = super.cachedResponse(for: request)
            let retVal = self.checkCachedResponse(cachedResponse)
            if retVal != nil {
                return retVal
            } else {
                return nil
            }
        }
        
        /// Returns cached response even its not valid.
        func cachedResponseWithForce(for request: URLRequest) -> CachedURLResponse? {
            return super.cachedResponse(for: request)
        }
        
        /// Calls the super class.
        override func removeCachedResponses(since date: Date) {
            super.removeCachedResponses(since: date)
        }
        
        /// Checks the response and acts accordingly
        override func getCachedResponse(for dataTask: URLSessionDataTask, completionHandler: @escaping (CachedURLResponse?) -> Void) {
            super.getCachedResponse(for: dataTask) { (cachedResponse) in
                if let response = self.checkCachedResponse(cachedResponse) {
                    completionHandler(response)
                } else {
                    completionHandler(nil)
                }
            }
        }
        
        /// Calls the super class.
        override func removeCachedResponse(for request: URLRequest) {
            super.removeCachedResponse(for: request)
        }
        
        /// Calls the super class.
        override func removeCachedResponse(for dataTask: URLSessionDataTask) {
            super.removeCachedResponse(for: dataTask)
        }
        
        /// Calls the super class.
        override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
            super.storeCachedResponse(cachedResponse, for: request)
        }
        
        /// Calls the super class.
        override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) {
            super.storeCachedResponse(cachedResponse, for: dataTask)
        }
        
        /// Calls the super class.
        override func removeAllCachedResponses() {
            super.removeAllCachedResponses()
        }
        
        /// Removes all the cache.
        @objc private func didReceiveMemoryWarning() {
            self.removeAllCachedResponses()
        }
        
    }
    
}

