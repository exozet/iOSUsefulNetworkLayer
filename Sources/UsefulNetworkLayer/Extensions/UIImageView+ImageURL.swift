//
//  UIImageView+ImageURL.swift
//  MyPet
//
//  Created by Burak Uzunboy on 23.05.20.
//  Copyright © 2020 BUZ. All rights reserved.
//

import UIKit

extension UIImageView {
    
    /// Creates and sets Image to the ImageView from given remote URL.
    ///
    /// During the loading process, this method is also capable to add activity indicator.
    /// Change tag value if other method will be called also to change image of the imageview to override again.
    open func imageFromUrl(urlString: String?, fallback: UIImage?, errorCompletion: ((_ error: NSError)->())? = nil){
        guard let urlStr = urlString, let url = URL(string: urlStr) else {
            self.image = fallback
            return
        }
        
        return self.imageFromUrl(url: url, fallback: fallback, errorCompletion: errorCompletion, completion: nil)
    }
    
    /**
     Sets image to the image view.
     - parameter url: URL of the image source
     - parameter completion: Returns the image that set to imageview even it fallbacks to error. If `fallback` is set, at worst it will return the fallback.
     - parameter errorCompletion: This block will be called if any error happens
     */
    open func imageFromUrl(url: URL?, fallback: UIImage?,
                             errorCompletion: ((_ error: NSError)->())? = nil,
                             completion: ((_ image: UIImage?)->())?) {
        guard let url = url else {
            self.image = fallback
            completion?(image)
            return
        }
        
        let dateTag = Int(Date().timeIntervalSince1970 * 1000)
        self.tag = dateTag
        self.image = nil
        
        // if image can be gathered from cache directly, use it.
        if let image = UIImage.fromCache(url) {
            self.image = image
            completion?(image)
            return
        }
        
        let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        activityIndicator.color = .orange
        activityIndicator.center = self.center
        activityIndicator.startAnimating()
        self.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        
        let request = APIConfiguration(url: url,
                                       responseBodyObject: ResponseImage.self,
                                       priority: .high, timeOut: 10)
        
        request.request { (result) in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                activityIndicator.removeFromSuperview()
                switch result {
                case .error(let error):
                    errorCompletion?(error.error)
                    if let fallback = fallback {
                        self.image = fallback
                    }
                    completion?(fallback)
                case .success(let image):
                    if self.tag == dateTag {
                        self.image = image.responseBody.image
                        completion?(image.responseBody.image)
                    }
                }
            }
        }
    }
    
}

/// Wrapper Class to convert Data to UIImage.
public class ResponseImage: ResponseBodyParsable {
    
    public static var shouldUseCustomInitializer: Bool { true }
    /// holds `UIImage` object inside.
    public var image: UIImage
    
    required init?(_ data: Data) {
        guard let image = UIImage(data: data) else {
            return nil
        }
        
        self.image = image
    }
    
    public func encode(to encoder: Encoder) throws {
        
    }
    
    required public init(from decoder: Decoder) throws {
        self.image = UIImage()
    }
    
    required init?(_ response: Any?) {
        return nil
    }
    
    public func cachingEndsAt() -> Date? {
        return Date().addingTimeInterval(60 * 60)
    }
    
}

