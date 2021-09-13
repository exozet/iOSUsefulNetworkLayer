// APIConfiguration.swift
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

/// Structure that keeps all information needed from Network Layer for operations.
public struct APIConfiguration<T,S> where T: ResponseBodyParsable, S: ErrorResponseParsable {
    /// Returns `URL` of the API request.
    public var requestURL: URL
    
    /// Type of the API request.
    public var requestType: NetworkLayer.RequestType
    
    /// Headers for the API request.
    public var headers: [String:String]?
    
    /// Request body for the API request.
    public var body: [String:Any]?
    
    /// Raw Request body for the API request.
    public var rawBody: Data?
    
    /// The expected object type from the request.
    public var responseBodyObject: T.Type
    
    /// The expected object type for the errors.
    public var errorResponseBodyObject: S.Type
    
    /// `NetworkLayer` priorities the API request by looking that parameter.
    public var priority: Operation.QueuePriority
    
    /// The desired expiration time for the API request.
    public var cachingTime: NetworkLayer.CachingTime
    
    /// `NetworkLayer` adds desired queue by looking that parameter.
    public var isMainOperation: Bool
    
    /// If `true`, the response will be cached by specified `cachingEndsAt` parameter of the response object.
    public var autoCache: Bool
    
    /// The timeout value for the request wait time.
    public var timeOut: Int
    
    /// The date decoding strategy. Default is .defferedToDate
    public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy
    
    /// HTTP Headers, iOS is using default headers for each HTTP request, e.g. the User-Agent. Use this to override them
    public var httpHeaders : [String: String]?


        
    /**
     Initializes Configuration with the host URL and endpoint separately.
     Returns nil if request URL cannot be created successfuly.
     - parameter hostURL: Base URL for the request. (e.g. "https://example.com")
     - parameter endPoint: Endpoint for the API request. (e.g. "v1/api/test")
     - parameter priority: Defines the priority of the operation in its queue.
     - parameter timeOut: Timeout value for the request to fail if it cannot get answer from network in seconds. In default, it's 30 seconds.
     - parameter cachingTime: Default caching time for the response, in default it's 1 hour.
     - parameter requestType: Type of the request. In default it's `get`.
     - parameter isMainOperation: If `true`, operation will be performed in special queue and return to main queue.
     - parameter headers: Headers for the API request. Don't need to add `content-Type` for JSON request bodies, which will be automatically added.
     - parameter body: Request body for the API request.
     - parameter responseBodyObject: Type of the Response Object to create.
     - parameter autoCache: To use that, override `cachingEndsAt:` method of Response Body Object.
     - parameter dateDecodingStrategy: The JSON date decoding strategy. Default is `.defferedToDate`
     - parameter httpHeaders:  iOS is using default headers for each HTTP request, e.g. the User-Agent. Use this to override them
     Then specified custom caching will be applied for that request.
     */
    public init?(hostURL: String, endPoint: String,
                 requestType: NetworkLayer.RequestType = .get,
                 headers: [String:String]? = nil,
                 body: [String:Any]? = nil,
                 rawBody: Data? = nil,
                 responseBodyObject: T.Type,
                 errorType: S.Type,
                 priority: Operation.QueuePriority = Operation.QueuePriority.normal,
                 cachingTime: NetworkLayer.CachingTime = NetworkLayer.CachingTime(seconds: 60 * 60),
                 isMainOperation: Bool = false,
                 autoCache: Bool = false,
                 timeOut: Int = 30,
                 dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                 httpHeaders: [String:String]? = nil) {
        
        var url = URL(string: hostURL)
        url?.appendPathComponent(endPoint)
        guard let requestURL = url else { return nil }
        
        self.init(url: requestURL,
                  requestType: requestType,
                  headers: headers,
                  body: body,
                  rawBody: rawBody,
                  responseBodyObject: responseBodyObject,
                  errorType: errorType,
                  priority: priority,
                  cachingTime: cachingTime,
                  isMainOperation: isMainOperation,
                  autoCache: autoCache,
                  timeOut: timeOut,
                  dateDecodingStrategy: dateDecodingStrategy,
                  httpHeaders: httpHeaders)
    }
    
    /**
     Initializes Configuration with the URL
     - parameter url: Request URL.
     - parameter priority: Defines the priority of the operation in its queue.
     - parameter timeOut: Timeout value for the request to fail if it cannot get answer from network in seconds. In default, it's 30 seconds.
     - parameter cachingTime: Default caching time for the response, in default it's 1 hour.
     - parameter requestType: Type of the request. In default it's `get`.
     - parameter isMainOperation: If `true`, operation will be performed in special queue and return to main queue.
     - parameter headers: Headers for the API request. Don't need to add `content-Type` for JSON request bodies, which will be automatically added.
     - parameter body: Request body for the API request.
     - parameter responseBodyObject: Type of the Response Object to create.
     - parameter autoCache: To use that, override `cachingEndsAt:` method of Response Body Object.
     - parameter dateDecodingStrategy: The JSON date decoding strategy. Default is `.defferedToDate`
     - parameter httpHeaders:  iOS is using default headers for each HTTP request, e.g. the User-Agent. Use this to override them
     Then specified custom caching will be applied for that request.
     */
    public init(url: URL,
                requestType: NetworkLayer.RequestType = .get,
                headers: [String:String]? = nil,
                body: [String:Any]? = nil,
                rawBody: Data? = nil,
                responseBodyObject: T.Type,
                errorType: S.Type,
                priority: Operation.QueuePriority = .normal,
                cachingTime: NetworkLayer.CachingTime = NetworkLayer.CachingTime(seconds: 60 * 60),
                isMainOperation: Bool = false,
                autoCache: Bool = false,
                timeOut: Int = 30,
                dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                httpHeaders: [String:String]? = nil) {
        
        self.requestURL = url
        self.requestType = requestType
        self.headers = headers
        self.body = body
        self.responseBodyObject = responseBodyObject
        self.priority = priority
        self.cachingTime = cachingTime
        self.isMainOperation = isMainOperation
        self.autoCache = autoCache
        self.timeOut = timeOut
        self.errorResponseBodyObject = errorType
        self.dateDecodingStrategy = dateDecodingStrategy
        self.rawBody = rawBody
        self.httpHeaders = httpHeaders
    }
    
    /// Tries to create URL request by specified parameters.
    var request: URLRequest? {
        
        // create url request with specified caching
        var request = URLRequest(url: self.requestURL,
                                 cachePolicy: .returnCacheDataElseLoad,
                                 timeoutInterval: TimeInterval(self.timeOut))
        
        // set http method
        request.httpMethod = self.requestType.rawValue
        // set headers
        request.allHTTPHeaderFields = headers
        
        // if request body is present, set json header and body together
        if let rawBody = rawBody {
            request.httpBody = rawBody
        }
        else if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                if !(request.allHTTPHeaderFields?.contains(where: { $0.key == "Content-Type"}) ?? false) {
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                }
                
            } catch {
                // error occurred
                return nil
            }
        }
        
        return request
    }
    
    /**
     Creates `APIOperation` for the specified task.
     - parameter task: The `URLSessionTask` created by the `NetworkLayer`
     - returns: `APIOperation` for the task and API configuration
     */
    internal func operation(with task: URLSessionTask, id: Int) -> NetworkLayer.APIOperation {
        let operation = NetworkLayer.APIOperation(configuration: self, task: task, identifier: id)
        return operation
    }
    
    /// Requests given API configuration by using `NetworkLayer`.
    /// - Parameter completion: Completion block which contains error or success case.
    /// - Parameter response: Response `Enum` which has two cases, whether `error` or `success`.
    @discardableResult
    public func request(completion: @escaping (_ response: NetworkLayer.Result<T,S>)->()) -> APITask? {
        var task: APITask?
        task = NetworkLayer.execute(self) { (result) in
            if (task?.isCancelled ?? false) { return }
            completion(result)
        }?.createAPITask()
        return task
    }
    
}

/// Operates to hold URL task after API is requested.
public class APITask {
    /// Cancels the operation. Completion block will not be called after task is being cancelled.
    public func cancel() {
        self.task?.cancel()
    }
    
    private var task: URLSessionTask?
    internal var isCancelled: Bool = false
    
    internal init(from task: URLSessionTask?) {
        self.task = task
    }
}

internal extension URLSessionTask {
    func createAPITask() -> APITask {
        return APITask(from: self)
    }
}

public extension APIConfiguration where T: ResponseBodyParsable, S == DefaultAPIError {
    
    /**
     Initializes Configuration with the host URL and endpoint separately. Initializes `DefaultAPIError` if any error occurs.
     Returns nil if request URL cannot be created successfuly.
     - parameter hostURL: Base URL for the request. (e.g. "https://example.com")
     - parameter endPoint: Endpoint for the API request. (e.g. "v1/api/test")
     - parameter priority: Defines the priority of the operation in its queue.
     - parameter timeOut: Timeout value for the request to fail if it cannot get answer from network in seconds. In default, it's 30 seconds.
     - parameter cachingTime: Default caching time for the response, in default it's 1 hour.
     - parameter requestType: Type of the request. In default it's `get`.
     - parameter isMainOperation: If `true`, operation will be performed in special queue and return to main queue.
     - parameter headers: Headers for the API request. Don't need to add `content-Type` for JSON request bodies, which will be automatically added.
     - parameter body: Request body for the API request.
     - parameter responseBodyObject: Type of the Response Object to create.
     - parameter autoCache: To use that, override `cachingEndsAt:` method of Response Body Object.
     - parameter dateDecodingStrategy: The JSON date decoding strategy. Default is `.defferedToDate`
     Then specified custom caching will be applied for that request.
     */
    init?(hostURL: String, endPoint: String,
          requestType: NetworkLayer.RequestType = .get,
          headers: [String:String]? = nil,
          body: [String:Any]? = nil,
          rawBody: Data? = nil,
          responseBodyObject: T.Type,
          priority: Operation.QueuePriority = Operation.QueuePriority.normal,
          cachingTime: NetworkLayer.CachingTime = NetworkLayer.CachingTime(seconds: 60 * 60),
          isMainOperation: Bool = false,
          autoCache: Bool = false,
          timeOut: Int = 30,
          dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate) {
        
        self.init(hostURL: hostURL,
                  endPoint: endPoint,
                  requestType: requestType,
                  headers: headers,
                  body: body,
                  rawBody: rawBody,
                  responseBodyObject: responseBodyObject,
                  errorType: DefaultAPIError.self,
                  priority: priority,
                  cachingTime: cachingTime,
                  isMainOperation: isMainOperation,
                  autoCache: autoCache,
                  timeOut: timeOut,
                  dateDecodingStrategy: dateDecodingStrategy)
    }
    
    /**
     Initializes Configuration with the URL and initializes `DefaultAPIError` if any error occurs.
     - parameter url: Request URL.
     - parameter priority: Defines the priority of the operation in its queue.
     - parameter timeOut: Timeout value for the request to fail if it cannot get answer from network in seconds. In default, it's 30 seconds.
     - parameter cachingTime: Default caching time for the response, in default it's 1 hour.
     - parameter requestType: Type of the request. In default it's `get`.
     - parameter isMainOperation: If `true`, operation will be performed in special queue and return to main queue.
     - parameter headers: Headers for the API request. Don't need to add `content-Type` for JSON request bodies, which will be automatically added.
     - parameter body: Request body for the API request.
     - parameter responseBodyObject: Type of the Response Object to create.
     - parameter autoCache: To use that, override `cachingEndsAt:` method of Response Body Object.
     - parameter dateDecodingStrategy: The JSON date decoding strategy. Default is `.defferedToDate`
     Then specified custom caching will be applied for that request.
     */
    init(url: URL,
         requestType: NetworkLayer.RequestType = .get,
         headers: [String:String]? = nil,
         body: [String:Any]? = nil,
         rawBody: Data? = nil,
         responseBodyObject: T.Type,
         priority: Operation.QueuePriority = .normal,
         cachingTime: NetworkLayer.CachingTime = NetworkLayer.CachingTime(seconds: 60 * 60),
         isMainOperation: Bool = false,
         autoCache: Bool = false,
         timeOut: Int = 30,
         dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate) {
        
        self.init(url: url,
                  requestType: requestType,
                  headers: headers,
                  body: body,
                  rawBody: rawBody,
                  responseBodyObject: responseBodyObject,
                  errorType: DefaultAPIError.self,
                  priority: priority,
                  cachingTime: cachingTime,
                  isMainOperation: isMainOperation,
                  autoCache: autoCache,
                  timeOut: timeOut,
                  dateDecodingStrategy: dateDecodingStrategy)
    }
}
