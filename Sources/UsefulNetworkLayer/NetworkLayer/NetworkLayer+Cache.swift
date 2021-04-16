// NetworkLayer+Cache.swift
//
// Copyright (c) 2020 Burak Uzunboy
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
#if !os(macOS) && !os(watchOS)
import UIKit
#endif

extension NetworkLayer {
    
    /// Custom Caching class.
    open class Cache: URLCache {
        
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
            #if !os(macOS) && !os(watchOS)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(didReceiveMemoryWarning),
                                                   name: UIApplication.didReceiveMemoryWarningNotification,
                                                   object: nil)
            #endif
        }
        
        /// Remove observer from the `NotificationCenter`
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
        
        /// Checks validity of the cached response with expiry value. Returns `nil` if its not valid.
        private func checkCachedResponse(_ response: CachedURLResponse?) -> CachedURLResponse? {
            guard let endDate = response?.userInfo?["cachingEndsAt"] as? Date else { return nil }
            
            if endDate > Date() {
                return response
            } else {
                return nil
            }
        }
        
        /// Checks the response and acts accordingly.
        override public func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
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
        override public func removeCachedResponses(since date: Date) {
            super.removeCachedResponses(since: date)
        }
        
        /// Checks the response and acts accordingly
        override public func getCachedResponse(for dataTask: URLSessionDataTask, completionHandler: @escaping (CachedURLResponse?) -> Void) {
            super.getCachedResponse(for: dataTask) { (cachedResponse) in
                if let response = self.checkCachedResponse(cachedResponse) {
                    completionHandler(response)
                } else {
                    completionHandler(nil)
                }
            }
        }
        
        /// Calls the super class.
        override public func removeCachedResponse(for request: URLRequest) {
            super.removeCachedResponse(for: request)
        }
        
        /// Calls the super class.
        override public func removeCachedResponse(for dataTask: URLSessionDataTask) {
            super.removeCachedResponse(for: dataTask)
        }
        
        /// Calls the super class.
        override public func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
            if cachedResponse.userInfo?["cachingEndsAt"] as? Date == nil {
                return
            }
            super.storeCachedResponse(cachedResponse, for: request)
        }
        
        /// Calls the super class.
        override public func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) {
            if cachedResponse.userInfo?["cachingEndsAt"] as? Date == nil {
                return
            }
            super.storeCachedResponse(cachedResponse, for: dataTask)
        }
        
        open func storeResponse(_ response: URLResponse, data: Data,
                                for request: URLRequest, expiry: Date) {
            let userInfo = ["cachingEndsAt": expiry]
            let cachedResponse = CachedURLResponse(response: response,
                                                   data: data,
                                                   userInfo: userInfo,
                                                   storagePolicy: .allowed)
            super.storeCachedResponse(cachedResponse, for: request)
        }
        
        /// Calls the super class.
        public func storeResponse(_ response: URLResponse, data: Data,
                                  for dataTask: URLSessionDataTask, expiry: Date) {
            let userInfo = ["cachingEndsAt": expiry]
            let cachedResponse = CachedURLResponse(response: response,
                                                   data: data,
                                                   userInfo: userInfo,
                                                   storagePolicy: .allowed)
            super.storeCachedResponse(cachedResponse, for: dataTask)
        }
        
        /// Calls the super class.
        override public func removeAllCachedResponses() {
            super.removeAllCachedResponses()
        }
        
        /// Removes all the cache.
        @objc private func didReceiveMemoryWarning() {
            self.removeAllCachedResponses()
        }
        
    }
    
}

