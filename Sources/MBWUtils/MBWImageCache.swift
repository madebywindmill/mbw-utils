//
//  MBWImageCache.swift
//  
//
//  Created by John Scalo on 10/24/22.
//

import UIKit

public class MBWImageCache {
    private let cache = NSCache<NSString,UIImage>()
    
    public init(sizeInMB: Int) {
        cache.name = "MBWImageCache"
        cache.totalCostLimit = sizeInMB * 1024 * 1024
    }
    
    public func removeAll() {
        cache.removeAllObjects()
    }
    
    public func cacheImage(_ image: UIImage, named name: String) {
        cache.setObject(image, forKey: name as NSString, cost: image.sizeInBytes)
    }
    
    public func imageNamed(_ name: String) -> UIImage? {
        return cache.object(forKey: name as NSString)
    }
    
}
