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
    public enum Result<T,S> where T: ResponseBodyParsable, S:ErrorResponseParsable {
        /// Returns when operation is succeed.
        case success(APIResponse<T>)
                
        /// Returns when operation faces with failure.
        case failure(APIError<T,S>)
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
    internal class func execute<T,S>(_ request: APIConfiguration<T,S>,
                                     completion: @escaping (Result<T,S>)->()) where T:ResponseBodyParsable, S: ErrorResponseParsable {
        let instance = NetworkLayer.shared
        DispatchQueue.global().async {
            guard let urlRequest = request.request else {
                let err = NSError(domain: "", code: 500, description: "Cannot create URL Request with specified configurations")
                instance.sendLog(message: err.localizedDescription, logType: .error(code: 900, name: err.localizedDescription))
                DispatchQueue.main.async {
                    var errorBody = S.init()
                    errorBody.error = err
                    completion(.failure(APIError(request: request, error: errorBody)))
                }
                return
            }
            
            // create task and operation
            let id = Int(Date().timeIntervalSince1970)
            var operation: APIOperation!
            var task: URLSessionDataTask!
            task = instance._urlSession.dataTask(with: urlRequest) { (data, response, error) in
                guard operation != nil else { return }
                
                var isCached = false
                instance.sendLog(message: "Data Task for Operation ID: \(operation.identifier) is completed - URL: \(urlRequest.url?.absoluteString ?? "nil")")
                operation.isFinished = true
                var dataResult = data ?? Data()
                var loadedResponse = response
                
                if let error = error {
                    if let oldCacheObject = instance._cache?.cachedResponseWithForce(for: urlRequest) {
                        dataResult = oldCacheObject.data
                        loadedResponse = oldCacheObject.response
                        isCached = true
                    } else {
                        instance.sendLog(message: "Operation:\(operation.identifier) failed with error: \(error.localizedDescription)", logType: .error(code: (error as NSError).code, name: error.localizedDescription))
                        DispatchQueue.main.async {
                            var errorBody = S.init()
                            errorBody.error = error
                            completion(.failure(.init(request: request, error: errorBody)))
                        }
                        return
                    }
                }
                
                instance.proceedResponse(response: loadedResponse!,
                                         data: dataResult,
                                         operationId: operation.identifier,
                                         request: request,
                                         isCachedResponse: isCached,
                                         dataTask: task,
                                         completion: completion)
            }
            
            instance._cache?.getCachedResponse(for: task, completionHandler: { (response) in
                if let response = response {
                    // found in the cache, proceed
                    instance.sendLog(message: "Operation with ID: \(id) is gathered from the cache - Caching ends: \(response.userInfo?["cachingEndsAt"] ?? "Nil")")
                    instance.proceedResponse(response: response.response,
                                             data: response.data,
                                             operationId: id,
                                             request: request,
                                             isCachedResponse: true,
                                             dataTask: task,
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
    private func proceedResponse<T,S>(response: URLResponse, data: Data,
                                      operationId: Int,
                                      request: APIConfiguration<T,S>,
                                      isCachedResponse: Bool,
                                      dataTask: URLSessionDataTask,
                                      completion: @escaping (Result<T,S>)->()) where T: ResponseBodyParsable, S: ErrorResponseParsable {
        
        let statusCode = (response as! HTTPURLResponse).statusCode
        
        guard (200..<400).contains(statusCode) else {
            var message = S.init()
            do {
                message.customMessage = (try JSONDecoder().decode(request.errorResponseBodyObject.T.self, from: data))
            } catch {
                self.sendLog(message: "Custom error message couldn't be created for Operation: \(operationId)", logType: .info)
            }
            self.sendLog(message: "HTTP Request failed with status \(statusCode) \(message)", logType: .error(code: statusCode, name: ""))
            DispatchQueue.main.async {
                completion(.failure(.init(request: request, error: message)))
            }
            return
        }
        
        guard data.count > 0 else {
            self.sendLog(message: "Data of the response is empty - Ignoring response creation - Operation: \(operationId)", logType: .info)
            DispatchQueue.main.async {
                completion(.success(.init(response: response,
                                          responseBody: nil,
                                          isCached: isCachedResponse)))
            }
            return
        }
        
        if !request.responseBodyObject.shouldUseCustomInitializer {
            do {
                let jsonObject = try JSONDecoder().decode(request.responseBodyObject, from: data)
                
                if request.autoCache, let cacheTiming = jsonObject.cachingEndsAt() {
                    self._cache?.storeResponse(response, data: data, for: dataTask, expiry: cacheTiming)
                } else {
                    self._cache?.storeResponse(response, data: data,
                                               for: dataTask, expiry: request.cachingTime.expirationDate ?? Date())
                }
                
                DispatchQueue.main.async {
                    completion(.success(.init(response: response,
                                              responseBody: jsonObject,
                                              isCached: isCachedResponse)))
                }
            } catch {
                var errorBody = S.init()
                errorBody.error = error
                DispatchQueue.main.async {
                    completion(.failure(.init(request: request, error: errorBody)))
                }
            }
            
            return
        }
        
        if let dataObject = request.responseBodyObject.init(data: data) {
            self.sendLog(message: "Data Object created from Operation: \(operationId) - Object: \(dataObject.typeName)")
            if request.autoCache, let cacheTiming = dataObject.cachingEndsAt() {
                self._cache?.storeResponse(response, data: data, for: dataTask, expiry: cacheTiming)
            } else {
                self._cache?.storeResponse(response, data: data,
                                           for: dataTask, expiry: request.cachingTime.expirationDate ?? Date())
            }
            DispatchQueue.main.async {
                completion(.success(APIResponse(response: response,
                                                responseBody: dataObject,
                                                isCached: isCachedResponse)))
            }
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
            if let responseObject = request.responseBodyObject.init(response: json) {
                self.sendLog(message: "Response Object Created from JSON Data with Operation: \(operationId) - Object: \(responseObject.typeName)")
                if request.autoCache, let cacheTiming = responseObject.cachingEndsAt() {
                    self._cache?.storeResponse(response, data: data, for: dataTask, expiry: cacheTiming)
                } else {
                    self._cache?.storeResponse(response, data: data,
                                                   for: dataTask, expiry: request.cachingTime.expirationDate ?? Date())
                }
                DispatchQueue.main.async {
                    completion(.success(APIResponse(response: response,
                                                    responseBody: responseObject,
                                                    isCached: isCachedResponse)))
                }
            } else {
                DispatchQueue.main.async {
                    let err = NSError(domain: "", code: 500, description: "Cannot create response body - Operation: \(operationId)")
                    var errorBody = S.init()
                    errorBody.error = err
                    completion(.failure(.init(request: request, error: errorBody)))
                }
            }
        } catch {
            self.sendLog(message: "Couldn't create JSON Data from Operation: \(operationId) - Error: \(error.localizedDescription)",
                logType: .error(code: 900, name: error.localizedDescription))
            DispatchQueue.main.async {
                let err = NSError(domain: "", code: 500, description: error.localizedDescription)
                var errorBody = S.init()
                errorBody.error = err
                completion(.failure(.init(request: request, error: errorBody)))
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
