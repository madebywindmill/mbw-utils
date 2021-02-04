//
//  MBWAppKitExtras.swift
//
//  Created by John Scalo on 2/3/21.
//  Copyright © 2018-2021 Made by Windmill. All rights reserved.
//

#if os(OSX)

import AppKit

extension NSImage {
        
    public func resize(targetSizePx: CGSize) -> NSImage {
        let size = self.size
        
        let widthRatio  = targetSizePx.width  / self.size.width
        let heightRatio = targetSizePx.height / self.size.height
        var newSize: CGSize
        
        if widthRatio > heightRatio {
            newSize = CGSize(width: floor(size.width * heightRatio), height: floor(size.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(size.width * widthRatio),  height: floor(size.height * widthRatio))
        }
        
        return self.resize(newSize)
    }
    
    public func resize(_ newSize: NSSize) -> NSImage {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height),
                  from: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height),
                  operation: .sourceOver,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
    
}


#endif
