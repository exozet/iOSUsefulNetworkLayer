//
//  NetworkLayer+CachingTime.swift
//  DCA_iOS
//
//  Created by Burak Uzunboy on 26.07.19.
//  Copyright © 2019 Exozet. All rights reserved.
//

import Foundation

public extension NetworkLayer {
    
    /// Helps to specify cache expiry value.
    class CachingTime {
        /// The expiration date for the cache object.
        var expirationDate: Date?
        
        /// Initialize the object with empty value.
        init() {
            self.expirationDate = nil
        }
        
        /**
         Initializes the timeobject to be cached up to specified time passed.
         - parameter seconds: Time represented by the seconds.
         */
        init(seconds: Double) {
            self.expirationDate = Date().addingTimeInterval(TimeInterval(exactly: seconds)!)
        }
        
        /**
         Initializes the timeobject to be cached up to specified date.
         - parameter expirationDate: The `Date` object.
         */
        init(until expirationDate: Date) {
            self.expirationDate = expirationDate
        }
    }
    
}
