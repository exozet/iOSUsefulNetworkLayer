//
//  NetworkLayer+APIOperation.swift
//  DCA_iOS
//
//  Created by Burak Uzunboy on 25.07.19.
//  Copyright © 2019 Exozet. All rights reserved.
//

import Foundation

extension NetworkLayer {
    
    /// Wrapper class for NSOperation.
    class APIOperation: BlockOperation {
        /// `true`.
        override var isAsynchronous: Bool { return true }
        
        /// returns internal property state.
        override var isFinished: Bool {
            get {
                return _isFinished
            }
            
            set {
                willChangeValue(forKey: "isFinished")
                _isFinished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
        
        /// internal property that holds the state.
        private var _isFinished: Bool = false
        
        // MARK: Input properties
        
        /// NetworkLayer instance to send messages.
        unowned var layerDelegate: NetworkLayer?
        
        /// The task that will be operated by the `NetworkLayer`.
        var task: URLSessionTask
        
        /// Unique identifier for the operation which created by the timestamp value.
        private(set) var identifier: Int
        
        
        /**
         Creates operation which includes URL task of the API.
         - parameter configuration: The API object which requests task.
         - parameter task: Task which will be operated for the API request.
         */
        init<T>(configuration: APIConfiguration<T>, task: URLSessionTask, identifier: Int) where T: ResponseBodyParsable {
            self.task = task
            self.identifier = identifier
            super.init()
            self.name = String(task.taskIdentifier)
        }
        
        /// Starts the URL task.
        override func start() {
            self.task.resume()
            self.layerDelegate?.sendLog(message: "Task with Operation ID: \(self.identifier) is started - URL: \(self.task.currentRequest?.url?.absoluteString ?? "nil")")
        }
        
        /// Cancels the URL task.
        override func cancel() {
            self.task.cancel()
            self.layerDelegate?.sendLog(message: "Task with Operation ID: \(self.identifier) is canceled - URL: \(self.task.currentRequest?.url?.absoluteString ?? "nil")")
        }
        
        /// Notifies `NetworkLayer` when deinitialization is completed.
        deinit {
            self.layerDelegate?.sendLog(message: "Operation with ID: \(self.identifier) is deinitializing")
        }
        
    }
    
    /// Defines available request types.
    enum RequestType: String {
        /// get type request
        case get = "GET"
        /// post type request
        case post = "POST"
        /// put type request
        case put = "PUT"
        /// delete type request
        case delete = "DELETE"
    }
    
}
