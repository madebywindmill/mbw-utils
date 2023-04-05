//
//  MBWImageCache.swift
//  
//
//  Created by John Scalo on 10/24/22.
//

#if os(iOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

/// Convenience layer above NSCache. Works with cgImage-based images, but not CoreImage-based images.
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
#if os(OSX)
        var rect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            print("MBWImageCache only works with cgImage-based images.")
            return
        }
        cache.setObject(image, forKey: name as NSString, cost: cgImage.bytesPerRow * cgImage.height)
#else
        guard let cgImage = image.cgImage else {
            print("MBWImageCache only works with cgImage-based images.")
            return
        }
        cache.setObject(image, forKey: name as NSString, cost: cgImage.bytesPerRow * cgImage.height)
#endif
    }
    
    public func imageNamed(_ name: String) -> Image? {
        return cache.object(forKey: name as NSString)
    }
}

