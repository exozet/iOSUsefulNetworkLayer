// APIStructs.swift
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
The response objects should be inherited from the `ResponseBodyParsable` to operate by the `NetworkLayer`.
*/
public protocol ResponseBodyParsable: Codable, NameDescribeable {
    /// To allow `NetworkLayer` to use defined initializer, set `true`, otherwise `Codable` protocol will be used.
    static var shouldUseCustomInitializer: Bool { get }
    /// Use this initializer to allow custom parsing from JSON object.
    init?(response: Any?)
    /// Use this initializer to allow custom parsing from Data directly.
    init?(data: Data)
    /// If custom value is defined, Caching will use this method to detect expiry.
    func cachingEndsAt() -> Date?
}

public extension ResponseBodyParsable {
    init?(response: Any?) { return nil }
    init?(data: Data) { return nil }
    func cachingEndsAt() -> Date? { return nil }
    static var shouldUseCustomInitializer: Bool { return false }
}

extension Array: NameDescribeable where Element: NameDescribeable {
    
}

extension Array: ResponseBodyParsable where Element: ResponseBodyParsable {
    
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

/// Network Layer will initializes error messages for the APIs with the given associatedType.
///
/// If no need to use custom types for the errors, use `DefaultAPIError`.
public protocol ErrorResponseParsable {
    associatedtype T: Codable
    var customMessage: T? { get set }
    var error: Error? { get set }
    init()
}

/// Default type for the APIs to use if any error occurs in the operation.
///
/// If any error occurs in the NetworkLayer independent from the API service, message will be carried
/// over the `error`, otherwise `customMessage` will be initialized.
public struct DefaultAPIError: ErrorResponseParsable {
    public init() { }
    public var customMessage: String?
    public var error: Error?
    public typealias T = String
}

/// Error result if the API request fails.
public struct APIError<T,S> where T: ResponseBodyParsable, S: ErrorResponseParsable {
    
    /// Error reason that explains why API request is failed.
    public private(set) var errorReason: S
    
    /// The API request that fails.
    public private(set) var api: APIConfiguration<T,S>
    
    internal init(request: APIConfiguration<T,S>, error: S) {
        self.api = request
        self.errorReason = error
    }

}
