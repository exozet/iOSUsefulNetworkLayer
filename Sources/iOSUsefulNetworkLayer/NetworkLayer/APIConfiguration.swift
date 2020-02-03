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
import iOSCoreUsefulSDK

/// Structure that keeps all information needed from Network Layer for operations.
public struct APIConfiguration<T> where T: ResponseBodyParsable {
    /// Returns `URL` of the API request.
    public var requestURL: URL
    
    /// Type of the API request.
    public var requestType: NetworkLayer.RequestType
    
    /// Headers for the API request.
    public var headers: [String:String]?
    
    /// Request body for the API request.
    public var body: [String:Any]?
    
    /// The expected object type from the request.
    public var responseBodyObject: T.Type
    
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
    
    /**
     Initializes Configuration with the host URL and endpoint separately.
     Returns nil if request URL cannot be created successfuly.
     - parameter isMainOperation: If `true`, operation will be performed in special queue and return to main queue.
     - parameter autoCache: To use that, override `cachingEndsAt:` method of Response Body Object.
     Then specified custom caching will be applied for that request.
     */
    public init?(hostURL: String, endPoint: String,
          requestType: NetworkLayer.RequestType = .get,
          headers: [String:String]? = nil,
          body: [String:Any]? = nil,
          responseBodyObject: T.Type,
          priority: Operation.QueuePriority = Operation.QueuePriority.normal,
          cachingTime: NetworkLayer.CachingTime = NetworkLayer.CachingTime(seconds: 60 * 60),
          isMainOperation: Bool = false,
          autoCache: Bool = false,
          timeOut: Int = 30) {
        
        var url = URL(string: hostURL)
        url?.appendPathComponent(endPoint)
        guard let requestURL = url else { return nil }
        
        self.requestURL = requestURL
        self.requestType = requestType
        self.headers = headers
        self.body = body
        self.responseBodyObject = responseBodyObject
        self.priority = priority
        self.cachingTime = cachingTime
        self.isMainOperation = isMainOperation
        self.autoCache = autoCache
        self.timeOut = timeOut
    }
    
    /**
     Initializes Configuration with the URL
     - parameter isMainOperation: If `true`, operation will be performed in special queue and return to main queue.
     - parameter autoCache: To use that, override `cachingEndsAt:` method of Response Body Object.
     Then specified custom caching will be applied for that request.
     */
    public init(url: URL,
         requestType: NetworkLayer.RequestType = .get,
         headers: [String:String]? = nil,
         body: [String:Any]? = nil,
         responseBodyObject: T.Type,
         priority: Operation.QueuePriority = .normal,
         cachingTime: NetworkLayer.CachingTime = NetworkLayer.CachingTime(seconds: 60 * 60),
         isMainOperation: Bool = false,
         autoCache: Bool = false,
         timeOut: Int = 30) {
        
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
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
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
    public func request(completion: @escaping (_ response: NetworkLayer.Result<T>)->()) {
        NetworkLayer.execute(self, completion: completion)
    }
    
}

/**
 The response objects should be inherited from the `ResponseBodyParsable` to operate by the `NetworkLayer`.
 */
open class ResponseBodyParsable: NSObject, NSDiscardableContent {
    
    /// Returns creation date of the response by the `NetworkLayer`.
    public private(set) var creationDate: Date
    
    /// Override this initializer to create responses from the `Data`.
    /// - parameter data: The response represented as `Data`
    required public init?(_ data: Data) {
        self.creationDate = Date()
    }
    
    /// Override this initializer to create responses from the `JSON` object.
    /// - parameter response: The `JSON` object as `Any` type which could be casted to `Dictionary` or `Array`
    required public init?(_ response: Any?) {
        self.creationDate = Date()
    }
    
    /// Returns `true` in default.
    public func beginContentAccess() -> Bool {
        print("\(self.typeName): Content access successful")
        return true
    }
    
    /// Doesn't do anything in default.
    public func endContentAccess() {
        print("\(self.typeName): Content cannot be accessed anymore")
    }
    
    /// Doesn't do anything in default.
    public func discardContentIfPossible() {
        print("\(self.typeName): Discard content called")
    }
    
    /// Returns `false` in default.
    public func isContentDiscarded() -> Bool {
        return false
    }
    
    /// Return specified parameter to work with `autoCache` API requests.
    public func cachingEndsAt() -> Date? {
        return nil
    }
}


/// Response of the API if request is completed successfully.
public struct APIResponse<T> where T: ResponseBodyParsable {
    
    /// Response body of the API request.
    public private(set) var responseBody: T
    
    /// Main URL response of the API request.
    public private(set) var response: URLResponse
    
    internal init(response: URLResponse, responseBody: T) {
        self.response = response
        self.responseBody = responseBody
    }
    
}

/// Error result if the API request fails.
public struct APIError<T> where T: ResponseBodyParsable {
    
    /// Error reason that explains why API request is failed.
    public private(set) var error: NSError
    
    /// The API request that fails.
    public private(set) var api: APIConfiguration<T>
    
    internal init(request: APIConfiguration<T>, error: NSError) {
        self.api = request
        self.error = error
    }

}
