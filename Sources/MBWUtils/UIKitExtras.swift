//
//  UIKitExtras.swift
//
//  Created by John Scalo on 12/21/17.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

#if os(iOS) || os(watchOS)

import UIKit
import CoreServices

public extension UIFont {
    var hasBold: Bool {
        return self.fontDescriptor.symbolicTraits.contains(.traitBold)
    }
    
    var hasItalic: Bool {
        return self.fontDescriptor.symbolicTraits.contains(.traitItalic)
    }
    
    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        return UIFont(descriptor: self.fontDescriptor.withSymbolicTraits(traits)!, size: self.pointSize)
    }
    
    func mergeTrait(_ trait: UIFontDescriptor.SymbolicTraits) -> UIFont? {
        guard let mergedDescriptor = self.fontDescriptor.withSymbolicTraits(trait.union(self.fontDescriptor.symbolicTraits)) else {
            return nil
        }
        return UIFont(descriptor: mergedDescriptor, size: self.pointSize)
    }
}

public extension UIColor {
    var hex3String: String {
       let components = self.cgColor.components
       let r: CGFloat = components?[0] ?? 0.0
       let g: CGFloat = components?[1] ?? 0.0
       let b: CGFloat = components?[2] ?? 0.0

       let hexString = String.init(format: "%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
       return hexString
    }
    
    static func blend(color1: UIColor, intensity1: CGFloat = 0.5, color2: UIColor, intensity2: CGFloat = 0.5) -> UIColor {
        let total = intensity1 + intensity2
        let l1 = intensity1/total
        let l2 = intensity2/total
        guard l1 > 0 else { return color2}
        guard l2 > 0 else { return color1}
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)

        color1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        color2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        return UIColor(red: l1*r1 + l2*r2, green: l1*g1 + l2*g2, blue: l1*b1 + l2*b2, alpha: l1*a1 + l2*a2)
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
       let components = self.cgColor.components
       let r: CGFloat = components?[0] ?? 0.0
       let g: CGFloat = components?[1] ?? 0.0
       let b: CGFloat = components?[2] ?? 0.0
       let a: CGFloat = components?[3] ?? 0.0

        let hexString = String.init(format: "%02lX%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)), lroundf(Float(a * 255)))
       return hexString
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

    //
    
    static func systemTintColor() -> UIColor {
        return UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
    }
    
    @available(*, deprecated, message: "Use hex3String instead")
    var hexString: String {
       let components = self.cgColor.components
       let r: CGFloat = components?[0] ?? 0.0
       let g: CGFloat = components?[1] ?? 0.0
       let b: CGFloat = components?[2] ?? 0.0

       let hexString = String.init(format: "%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
       return hexString
    }
    
    @available(*, deprecated, message: "Use UIColor(hex3:) instead")
    static func colorFromHex(_ hex: Int) -> UIColor {
        let redPart = CGFloat((hex >> 16) & 0xff)/255.0
        let greenPart = CGFloat((hex >> 8) & 0xff)/255.0
        let bluePart = CGFloat(hex & 0xff)/255.0
        return UIColor(red: redPart, green: greenPart, blue: bluePart, alpha: 1.0)
    }

    @available(*, deprecated, message: "Use UIColor(hex3String:) instead")
    static func colorFromHexStr(_ hexStr: String) -> UIColor {
        var hexInt: UInt64 = 0
        let scanner: Scanner = Scanner(string: hexStr)
        scanner.scanHexInt64(&hexInt)
        let int = Int(hexInt)
        return colorFromHex(int)
    }
}

public extension UIImage {
    
    @available(iOS 13.0, *)
    convenience init?(systemName: String, pointSize: CGFloat, weight: UIImage.SymbolWeight) {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        self.init(systemName: systemName, withConfiguration: config)
    }

    /// Searches for a resource of this name (including the extension) in the app's main bundle and returns the image.
    convenience init?(fromMainBundleResourceName name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        self.init(data: data)
    }

    /// Resize to `newSize` using screen points by default or `scale` if provided.
    func resize(to newSize: CGSize, scale: CGFloat = 0) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))

        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Resize to the new width using screen points by default or `scale` if provided.
    func resize(newWidth: CGFloat, scale: CGFloat = 0) -> UIImage? {
        let r = newWidth / size.width
        let newHeight = size.height * r
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// Resize to the new height using screen points by default or `scale` if provided.
    func resize(newHeight: CGFloat, scale: CGFloat = 0) -> UIImage? {
        let r = newHeight / size.height
        let newWidth = size.width * r
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// Resize the image to the target size, using an "aspect fit" strategy. The new size uses the native scale of the source image.
    func resize(targetSizePx: CGSize) -> UIImage? {
        let widthRatio  = targetSizePx.width  / size.width
        let heightRatio = targetSizePx.height / size.height
        var newSize: CGSize
        
        if widthRatio > heightRatio {
            newSize = CGSize(width: floor(size.width * heightRatio), height: floor(size.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(size.width * widthRatio),  height: floor(size.height * widthRatio))
        }
        
        newSize.width /= scale
        newSize.height /= scale
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
        draw(in: rect)

        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// Returns a size that will fit the image with a maximum "side", i.e. length or width. The new size uses the native scale of the source image.
    func sizePxForMaxSide(_ maxSide: CGFloat) -> CGSize {
        var sizePx = size
        sizePx.width *= scale
        sizePx.height *= scale
        
        // If we're already smaller than max on both sides, return current size in px.
        if max(sizePx.width, sizePx.height) < maxSide {
            return size
        }
        
        let widthRatio  = maxSide  / size.width
        let heightRatio = maxSide / size.height
        var newSize: CGSize
        
        if widthRatio > heightRatio {
            newSize = CGSize(width: floor(sizePx.width * heightRatio), height: floor(sizePx.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(sizePx.width * widthRatio),  height: floor(sizePx.height * widthRatio))
        }
        
        return newSize
    }

    func resample(bpc: Int) -> UIImage? {
        let imageRect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        guard let context = CGContext(data: nil,
                                width: Int(self.size.width),
                                height: Int(self.size.height),
                                bitsPerComponent: bpc,
                                bytesPerRow: Int(self.size.width) * 4,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue) else {
                                    return nil
        }
        context.draw(self.cgImage!, in: imageRect)
        guard let cgImage = context.makeImage() else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    // returns the same image but with an orientation of .up. (note: can be slow.)
    func fixOrientation() -> UIImage {
        guard let cgImage = cgImage else { return self }
        if imageOrientation == .up { return self }
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: CGFloat.pi/2.0)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: CGFloat.pi / -2.0)
        case .up, .upMirrored:
            break
        @unknown default:
            assertionFailure()
        }
        
        // TODO: fix calls to translatedBy, scaledBy and test.
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform.translatedBy(x: size.width, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform.translatedBy(x: size.height, y: 0)
            transform.scaledBy(x: -1, y: 1)
        case .up, .down, .left, .right:
            break
        @unknown default:
            assertionFailure()
        }
        
        if let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0, space: cgImage.colorSpace!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
            ctx.concatenate(transform)
            switch imageOrientation {
            case .left, .leftMirrored, .right, .rightMirrored:
                ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
            default:
                ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            }
            if let finalImage = ctx.makeImage() {
                return (UIImage(cgImage: finalImage))
            }
        }
        
        // something failed, return original
        return self
    }
    
    class func image(with color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y:0), size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
    }
    
    func crop(rect: CGRect) -> UIImage {
        let fixedImage = self.fixOrientation()
        let imageRef = fixedImage.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: fixedImage.scale, orientation: fixedImage.imageOrientation)
        return image
    }
    
    func crop(aspect: CGFloat) -> UIImage {
        let fixedImage = self.fixOrientation()
        let size = fixedImage.size
        let myAspect = size.width/size.height
        var cropRect = CGRect()
        if size.width > size.height {
            if aspect < myAspect {
                // landscape image, portrait aspect. crop down the center.
                let newWidth = aspect * size.height
                cropRect = CGRect(x: size.width/2 - newWidth/2, y: 0, width: newWidth, height: size.height)
            } else {
                // landscape image, landscape aspect. crop top part (hoping to preserve faces.)
                let newHeight = size.width / aspect
                cropRect = CGRect(x: 0, y: 0, width: size.width, height: newHeight)
            }
        } else {
            if aspect < myAspect {
                // portrait image, portrait aspect. crop down the center.
                let newWidth = aspect * size.height
                cropRect = CGRect(x: size.width/2 - newWidth/2, y: 0, width: newWidth, height: size.height)
            } else {
                // portrait image, landscape aspect. crop top part (hoping to preserve faces.)
                let newHeight = size.width / aspect
                cropRect = CGRect(x: 0, y: newHeight - size.height, width: size.width, height: size.height)
            }
        }
        
        let imageRef = fixedImage.cgImage!.cropping(to: cropRect)
        let image = UIImage(cgImage: imageRef!, scale: fixedImage.scale, orientation: fixedImage.imageOrientation)
        return image
    }
    
    func rectOfCrop(toAspect aspect: CGFloat) -> CGRect {
        let fixedImage = self.fixOrientation()
        let size = fixedImage.size
        let myAspect = size.width/size.height
        var cropRect = CGRect()
        if size.width > size.height {
            if aspect < myAspect {
                // landscape image, portrait aspect. crop down the center.
                let newWidth = aspect * size.height
                cropRect = CGRect(x: size.width/2 - newWidth/2, y: 0, width: newWidth, height: size.height)
            } else {
                // landscape image, landscape aspect. crop top part (hoping to preserve faces.)
                let newHeight = size.width / aspect
                cropRect = CGRect(x: 0, y: 0, width: size.width, height: newHeight)
            }
        } else {
            if aspect < myAspect {
                // portrait image, portrait aspect. crop down the center.
                let newWidth = aspect * size.height
                cropRect = CGRect(x: size.width/2 - newWidth/2, y: 0, width: newWidth, height: size.height)
            } else {
                // portrait image, landscape aspect. crop top part (hoping to preserve faces.)
                let newHeight = size.width / aspect
                cropRect = CGRect(x: 0, y: newHeight - size.height, width: size.width, height: size.height)
            }
        }
        
        return cropRect
    }

    func applyingBorder(color: UIColor, size: CGFloat) -> UIImage {
        let imgSize = self.size
        UIGraphicsBeginImageContext(imgSize)
        let rect = CGRect(x: 0, y: 0, width: imgSize.width, height: imgSize.height)
        self.draw(in: rect)
        
        guard let ctx = UIGraphicsGetCurrentContext() else {
            fatalError("couldn't get gfx context")
        }
        
        let strokeRect = rect.insetBy(dx: 0.5, dy: 0.5)
        ctx.setStrokeColor(color.cgColor)
        ctx.setLineWidth(size)
        ctx.stroke(strokeRect)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            fatalError("couldn't make image")
        }
        UIGraphicsEndImageContext()
        return image
    }
    
    func getUnderlyingData() -> Data? {
        if let dataProvider = self.cgImage?.dataProvider, let underlyingData = dataProvider.data as Data? {
            return underlyingData
        } else {
            return nil
        }
    }
    
    var sizeInBytes: Int {
        guard let cgImage = self.cgImage else {
            assertionFailure()
            return 0
        }
        return cgImage.bytesPerRow * cgImage.height
    }

}

public extension UIEdgeInsets {
    mutating func offset(by offset: UIEdgeInsets) {
        top -= offset.top
        left -= offset.left
        bottom -= offset.bottom
        right -= offset.right
    }
}

#endif // os(iOS) || os(watchOS)

public enum DiffableDatasourceGenericSection: Int {
    case main = 0
}
