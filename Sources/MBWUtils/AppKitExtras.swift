//
//  AppKitExtras.swift
//
//  Created by John Scalo on 2/3/21.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

#if os(OSX)

import AppKit

public extension NSColor {
    var hex3String: String {
        guard let colorSpace = self.cgColor.colorSpace else {
            assertionFailure("couldn't get colorSpace")
            return "000000"
        }
        guard let components = self.cgColor.components else {
            assertionFailure("couldn't get color components")
            return "000000"
        }
        
        switch colorSpace.model {
            case .rgb:
                guard components.count >= 3 else {
                    assertionFailure("unexpected number of color components")
                    return "000000"
                }
                let r: CGFloat = components[0]
                let g: CGFloat = components[1]
                let b: CGFloat = components[2]
                return String(
                    format: "%02lX%02lX%02lX",
                    lroundf(Float(r * 255)),
                    lroundf(Float(g * 255)),
                    lroundf(Float(b * 255))
                )
                
            case .monochrome:
                guard components.count >= 1 else {
                    assertionFailure("unexpected number of color components")
                    return "000000"
                }
                let white: CGFloat = components[0]
                return String(
                    format: "%02lX%02lX%02lX",
                    lroundf(Float(white * 255)),
                    lroundf(Float(white * 255)),
                    lroundf(Float(white * 255))
                )
                
            default:
                assertionFailure("unknown colorspace: \(colorSpace.model)")
                return "000000"
        }
    }
    
    convenience init(hex3: Int) {
        let r = CGFloat((hex3 >> 16) & 0xff)/255.0
        let g = CGFloat((hex3 >> 8) & 0xff)/255.0
        let b = CGFloat(hex3 & 0xff)/255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
    
    convenience init(hex3String: String) {
        var hexInt: UInt64 = 0
        let scanner: Scanner = Scanner(string: hex3String)
        scanner.scanHexInt64(&hexInt)
        let int = Int(hexInt)
        self.init(hex3: int)
    }
    
    var hex4String: String {
        guard let components = self.cgColor.components else {
            assertionFailure("couldn't get color components")
            return "000000"
        }
        
        guard components.count >= 4 else {
            assertionFailure("unexpected number of color components")
            return "000000"
        }

        let r: CGFloat = components[0]
        let g: CGFloat = components[1]
        let b: CGFloat = components[2]
        let a: CGFloat = components[3]
        
        return String.init(
            format: "%02lX%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255)),
            lroundf(Float(a * 255))
        )
    }

    convenience init(hex4: Int) {
        let r = CGFloat((hex4 >> 24) & 0xff)/255.0
        let g = CGFloat((hex4 >> 16) & 0xff)/255.0
        let b = CGFloat((hex4 >> 8) & 0xff)/255.0
        let a = CGFloat(hex4 & 0xff)/255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    // CSS convention: RRGGBBAA
    convenience init(hex4String: String) {
        var hexInt: UInt64 = 0
        let scanner: Scanner = Scanner(string: hex4String)
        scanner.scanHexInt64(&hexInt)
        let int = Int(hexInt)
        self.init(hex4: int)
    }

    // Display P3 color profile support
    
    convenience init(p3r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) {
        self.init(displayP3Red: p3r, green: g, blue: b, alpha: a)
    }
    
    convenience init(p3hex3: Int) {
        let r = CGFloat((p3hex3 >> 16) & 0xff)/255.0
        let g = CGFloat((p3hex3 >> 8) & 0xff)/255.0
        let b = CGFloat(p3hex3 & 0xff)/255.0
        self.init(p3r: r, g, b)
    }

    convenience init(p3hex3String: String) {
        var hexInt: UInt64 = 0
        let scanner: Scanner = Scanner(string: p3hex3String)
        scanner.scanHexInt64(&hexInt)
        let int = Int(hexInt)
        self.init(p3hex3: int)
    }

    convenience init(p3hex4: Int) {
        let r = CGFloat((p3hex4 >> 24) & 0xff)/255.0
        let g = CGFloat((p3hex4 >> 16) & 0xff)/255.0
        let b = CGFloat((p3hex4 >> 8) & 0xff)/255.0
        let a = CGFloat(p3hex4 & 0xff)/255.0
        self.init(p3r: r, g, b, a)
    }

    convenience init(p3hex4String: String) {
        var hexInt: UInt64 = 0
        let scanner: Scanner = Scanner(string: p3hex4String)
        scanner.scanHexInt64(&hexInt)
        let int = Int(hexInt)
        self.init(p3hex4: int)
    }
}

public extension NSImage {
    
    func jpegData(compressionQuality: CGFloat) -> Data? {
        let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [.compressionFactor:compressionQuality])
    }
    
    func pngData() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation else {
            return nil
        }

        guard let bitmapImageRep = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }

        return bitmapImageRep.representation(using: .png, properties: [:])
    }

    // Returns optional to conform with UIImage.resize(targetSizePx:)
    func resize(targetSizePx: CGSize) -> NSImage? {
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
    
    // Returns optional to conform with UIImage.resize()
    func resize(_ newSize: NSSize) -> NSImage? {
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
    
    var sizeInBytes: Int {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            assertionFailure()
            return 0
        }
        return cgImage.bytesPerRow * cgImage.height
    }

}


#endif
