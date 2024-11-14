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
public final class MBWImageCache: @unchecked Sendable {
    private let cache = NSCache<NSString,CocoaImage>()
    private let queue = DispatchQueue(label: "com.madebywindmill.imagecache.queue", attributes: .concurrent)

    public init(sizeInMB: Int) {
        cache.name = "MBWImageCache"
        cache.totalCostLimit = sizeInMB * 1024 * 1024
    }
    
    public func removeAll() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAllObjects()
        }
    }
    
    public func cacheImage(_ image: CocoaImage, named name: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
#if os(OSX)
            var rect = NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
                print("MBWImageCache only works with cgImage-based images.")
                return
            }
#else
            guard let cgImage = image.cgImage else {
                print("MBWImageCache only works with cgImage-based images.")
                return
            }
#endif
            
            cache.setObject(image, forKey: name as NSString, cost: cgImage.bytesPerRow * cgImage.height)
        }
    }
    
    public func imageNamed(_ name: String) -> CocoaImage? {
        var result: CocoaImage?
        queue.sync {
            result = cache.object(forKey: name as NSString)
        }
        return result
    }
    
    public func removeImage(named name: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeObject(forKey: name as NSString)
        }
    }
}

