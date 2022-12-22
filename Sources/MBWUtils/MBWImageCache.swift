//
//  MBWImageCache.swift
//  
//
//  Created by John Scalo on 10/24/22.
//

#if os(iOS)  || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

public class MBWImageCache {
    private let cache = NSCache<NSString,Image>()
    
    public init(sizeInMB: Int) {
        cache.name = "MBWImageCache"
        cache.totalCostLimit = sizeInMB * 1024 * 1024
    }
    
    public func removeAll() {
        cache.removeAllObjects()
    }
    
    public func cacheImage(_ image: Image, named name: String) {
        cache.setObject(image, forKey: name as NSString, cost: image.sizeInBytes)
    }
    
    public func imageNamed(_ name: String) -> Image? {
        return cache.object(forKey: name as NSString)
    }
    
}
