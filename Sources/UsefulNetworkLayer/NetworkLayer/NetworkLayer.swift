// NetworkLayer.swift
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
import CoreUsefulSDK

/**
 Base Network Layer that capable to cache and manage the operation queue.
 */
public class NetworkLayer: NSObject, URLSessionDataDelegate {
    
    /**
     Network Layer operations completes block with the Response type.
     
     Response will whether return error as `NSError` or the success with the specified type of response object.
     */
    public enum Result<T> where T: ResponseBodyParsable {
        /// Returns response.
        case success(APIResponse<T>)
        /// Returns reason of the error.
        case error(APIError<T>)
    }

    
    // MARK: - Properties
    
    /// Holds cache of the `NetworkLayer`.
    public class var cache: Cache? {
        get { return NetworkLayer.shared._cache }
    }
    
    public class var urlSession: URLSession {
        get { return NetworkLayer.shared._urlSession }
        set { NetworkLayer.shared._urlSession = newValue }
    }
    
    /// Singleton instance for the `NetworkLayer`.
    private static let shared = NetworkLayer()
    
    /// Operations marked as main are being handled by this queue.
    var mainQueue: OperationQueue {
        didSet {
            self.mainQueue.maxConcurrentOperationCount = 1
            self.mainQueue.qualityOfService = .userInitiated
            self.mainQueue.name = "\(Bundle.main.bundleIdentifier!).operationQueue"
        }}
    
    /// Operations not marked as main queue are being handled by this queue.
    var backgroundQueue: OperationQueue {
        didSet {
            self.backgroundQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
            self.backgroundQueue.qualityOfService = .default
            self.backgroundQueue.name = "\(Bundle.main.bundleIdentifier!).backgroundQueue"
        }}
        
    /// Holds cache of the `NetworkLayer`.
    public var _cache: Cache? {
        get {
            return NetworkLayer.Cache(memoryCapacity: 0,
                                      diskCapacity: 150 * 1024 * 1024,
                                      diskPath: nil)
        }
    }
    
    /// `URLSession` manager for the `NetworkLayer`.
    public var _urlSession: URLSession!
    
    /// Private initializer
    private override init() {
        self.mainQueue = OperationQueue()
        self.backgroundQueue = OperationQueue()
        super.init()
        
        let conf = URLSessionConfiguration.default
        conf.requestCachePolicy = .reloadIgnoringCacheData
        conf.urlCache = self._cache
        
        self._urlSession = URLSession.init(configuration: conf,
                                          delegate: self,
                                          delegateQueue: nil)
    }
    
    /// Removes observers.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: Internal Methods
    
    /**
     Executes configured API.
     - parameter request: All information/configurations needed to execute API
     - parameter completion: Completion block which will be called when operation is completed
     - parameter error: Returns reason of the error if operation fails. `nil` otherwise
     - parameter response: Returns response with the specified type of response
     */
    internal class func execute<T>(_ request: APIConfiguration<T>, completion: @escaping (Result<T>)->()) where T:ResponseBodyParsable {
        let instance = NetworkLayer.shared
        DispatchQueue.global().async {
            guard let urlRequest = request.request else {
                let err = NSError(domain: "", code: 500, description: "Cannot create URL Request with specified configurations")
                instance.sendLog(message: err.localizedDescription, logType: .error(code: 900, name: err.localizedDescription))
                DispatchQueue.main.async {
                    completion(.error(APIError(request: request, error: err)))
                }
                return
            }
            
            // create task and operation
            let id = Int(Date().timeIntervalSince1970 * 1000)
            var operation: APIOperation!
            var task: URLSessionDataTask!
            
            task = instance._urlSession.dataTask(with: urlRequest) { (data, response, error) in
                guard operation != nil else { return }
                
                instance.sendLog(message: "Data Task for Operation ID: \(operation.identifier) is completed - URL: \(urlRequest.url?.absoluteString ?? "nil")")
                operation.isFinished = true
                var dataResult = data
                var loadedResponse = response
                
                if let error = error {
                    if let oldCacheObject = instance._cache?.cachedResponseWithForce(for: urlRequest) {
                        dataResult = oldCacheObject.data
                        loadedResponse = oldCacheObject.response
                    } else {
                        instance.sendLog(message: "Operation:\(operation.identifier) failed with error: \(error.localizedDescription)", logType: .error(code: (error as NSError).code, name: error.localizedDescription))
                        DispatchQueue.main.async {
                            completion(.error(.init(request: request, error: error as NSError)))
                        }
                        return
                    }
                }
                
                instance._cache?.changeCacheExpiry(for: task, to: request.cachingTime.expirationDate ?? Date())
                
                guard let data = dataResult, let loadResponse = loadedResponse else {
                    let err = NSError(domain: "", code: 500, description: "Data is empty - Operation: \(operation.identifier)")
                    DispatchQueue.main.async {
                        completion(.error(.init(request: request, error: err)))
                    }
                    return
                }
                
                instance.proceedResponse(response: loadResponse, data: data, operationId: operation.identifier, request: request, completion: completion)
            }
            
            instance._cache?.getCachedResponse(for: task, completionHandler: { (response) in
                if let response = response {
                    // found in the cache, proceed
                    instance.sendLog(message: "Operation with ID: \(id) is gathered from the cache - Caching ends: \(response.userInfo?["cachingEndsAt"] ?? "Nil")")
                    instance.proceedResponse(response: response.response,
                                         data: response.data,
                                         operationId: id,
                                         request: request,
                                         completion: completion)
                    task.cancel()
                } else {
                    operation = request.operation(with: task, id: id)
                    instance.sendLog(message: "Operation with ID: \(operation.identifier) is created - URL: \(request.requestURL)")
                    operation.layerDelegate = instance
                    request.isMainOperation ? instance.mainQueue.addOperation(operation) : instance.backgroundQueue.addOperation(operation)
                    
                    operation.completionBlock = {
                        instance.sendLog(message: "Operation with ID: \(operation.identifier) is completed")
                    }
                    
                    instance.sendLog(message: "Operation with ID: \(operation.identifier) is added to queue - isMainQueue: \(request.isMainOperation)")
                }
            })
        }
    }
    
    // MARK: Private Methods
    
    /// Proceeds the response and completes.
    private func proceedResponse<T>(response: URLResponse, data: Data,
                                    operationId: Int,
                                    request: APIConfiguration<T>,
                                    completion: @escaping (Result<T>)->()) where T: ResponseBodyParsable {
        
        if !request.responseBodyObject.shouldUseCustomInitializer {
            do {
                let jsonObject = try JSONDecoder().decode(request.responseBodyObject, from: data)
                completion(.success(.init(response: response, responseBody: jsonObject)))
            } catch {
                completion(.error(.init(request: request, error: error as NSError)))
            }
            
            return
        }
        
        if let dataObject = request.responseBodyObject.init(data: data) {
            self.sendLog(message: "Data Object created from Operation: \(operationId) - Object: \(dataObject.typeName)")
            if request.autoCache, let cacheTiming = dataObject.cachingEndsAt() {
                self._cache?.changeCacheExpiry(for: request.request!, to: cacheTiming)
            }
            DispatchQueue.main.async {
                completion(.success(APIResponse(response: response, responseBody: dataObject)))
            }
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if let responseObject = request.responseBodyObject.init(response: json) {
                self.sendLog(message: "Response Object Created from JSON Data with Operation: \(operationId) - Object: \(responseObject.typeName)")
                if request.autoCache, let cacheTiming = responseObject.cachingEndsAt() {
                    self._cache?.changeCacheExpiry(for: request.request!, to: cacheTiming)
                }
                DispatchQueue.main.async {
                    completion(.success(APIResponse(response: response, responseBody: responseObject)))
                }
            } else {
                DispatchQueue.main.async {
                    let err = NSError(domain: "", code: 500, description: "Cannot create response body - Operation: \(operationId)")
                    completion(.error(.init(request: request, error: err)))
                }
            }
        } catch {
            self.sendLog(message: "Couldn't create JSON Data from Operation: \(operationId) - Error: \(error.localizedDescription)",
                logType: .error(code: 900, name: error.localizedDescription))
            DispatchQueue.main.async {
                let err = NSError(domain: "", code: 500, description: error.localizedDescription)
                completion(.error(.init(request: request, error: err)))
            }
        }
    }
        
    /**
     Sends logs to listener. Shouldn't be called outside of the `NetworkLayer`.
     - parameter message: Log message
     - parameter function: Caller of the log
     */
    internal func sendLog(message: String, function: String = #function, logType: LogType = .info) {
        switch logType {
        case .info:
            LoggingManager.info(message: message, domain: .service, function: function)
        case .error(code: let code, name: let name):
            LoggingManager.error(message: message, domain: .service, function: function, tracking: (code, name))
        }
    }
    
    /// Two log type is currently possible. Info or error with the code and name.
    internal enum LogType {
        /// Default log type for the network layer
        case info
        /// Logs with the code and name of the error
        case error(code: Int, name: String)
    }
    
}
