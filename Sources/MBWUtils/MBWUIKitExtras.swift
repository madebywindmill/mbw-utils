//
//  MBWUIKitExtras.swift
//
//  Created by John Scalo on 12/21/17.
//  Copyright © 2018-2021 Made by Windmill. All rights reserved.
//

import UIKit

extension UIApplication {
    public var icon: UIImage? {
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? NSDictionary,
            let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? NSDictionary,
            let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? NSArray,
            // First will be smallest for the device class, last will be the largest for device class
            let lastIcon = iconFiles.lastObject as? String,
            let icon = UIImage(named: lastIcon) else {
                return nil
        }

        return icon
    }
}

public class SFSymbolsFixButton: UIButton {
    public override func awakeFromNib() {
        super.awakeFromNib()
        fixScalingIssueWithSFSymbols()
    }
}

extension UIDevice {
    public var modelID: String {
        get {
            var systemInfo = utsname()
            uname(&systemInfo)
            let modelCode = withUnsafePointer(to: &systemInfo.machine) {
                $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                    ptr in String.init(validatingUTF8: ptr)
                }
            }
            
            if modelCode != nil {
                return modelCode!
            } else {
                return "unknown"
            }
        }
    }
}

extension UIButton {
    public func fixScalingIssueWithSFSymbols() {
        imageView?.contentMode = .scaleAspectFit
    }
    
    public func setTitle(_ title: String?, for state: UIControl.State, animated: Bool = false) {
        if !animated {
            UIView.setAnimationsEnabled(false)
        }
        
        setTitle(title, for: state)
        
        if !animated {
            UIView.setAnimationsEnabled(true)
        }
    }
    
    public func setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State, animated: Bool = false) {
        if !animated {
            UIView.setAnimationsEnabled(false)
        }
        
        setAttributedTitle(title, for: state)
//        layoutIfNeeded()
        
        if !animated {
            UIView.setAnimationsEnabled(true)
        }
    }

}

extension UIFont {
    public var weight: UIFont.Weight {
        guard let weightNumber = traits[.weight] as? NSNumber else { return .regular }
        let weightRawValue = CGFloat(weightNumber.doubleValue)
        let weight = UIFont.Weight(rawValue: weightRawValue)
        return weight
    }

    public var traits: [UIFontDescriptor.TraitKey: Any] {
        return fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
            ?? [:]
    }
    
    public func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        return UIFont(descriptor: self.fontDescriptor.withSymbolicTraits(traits)!, size: self.pointSize)
    }

    public func asSFRounded() -> UIFont {
        if #available(iOS 13.0, *) {
            let fontSize = self.pointSize
            let systemFont = UIFont.systemFont(ofSize: fontSize, weight: self.weight)

            let font: UIFont

            if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
                font = UIFont(descriptor: descriptor, size: fontSize)
            } else {
                font = systemFont
            }

            return font
        } else {
            return self
        }
    }

}

extension UIColor {
    public var hex3String: String {
       let components = self.cgColor.components
       let r: CGFloat = components?[0] ?? 0.0
       let g: CGFloat = components?[1] ?? 0.0
       let b: CGFloat = components?[2] ?? 0.0

       let hexString = String.init(format: "%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
       return hexString
    }
    
    public convenience init(hex3: Int) {
        let r = CGFloat((hex3 >> 16) & 0xff)/255.0
        let g = CGFloat((hex3 >> 8) & 0xff)/255.0
        let b = CGFloat(hex3 & 0xff)/255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
    
    public convenience init(hex3String: String) {
        var hexInt: UInt64 = 0
        let scanner: Scanner = Scanner(string: hex3String)
        scanner.scanHexInt64(&hexInt)
        let int = Int(hexInt)
        self.init(hex3: int)
    }
    
    public var hex4String: String {
       let components = self.cgColor.components
       let r: CGFloat = components?[0] ?? 0.0
       let g: CGFloat = components?[1] ?? 0.0
       let b: CGFloat = components?[2] ?? 0.0
       let a: CGFloat = components?[3] ?? 0.0

        let hexString = String.init(format: "%02lX%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)), lroundf(Float(a * 255)))
       return hexString
    }

    public convenience init(hex4: Int) {
        let r = CGFloat((hex4 >> 24) & 0xff)/255.0
        let g = CGFloat((hex4 >> 16) & 0xff)/255.0
        let b = CGFloat((hex4 >> 8) & 0xff)/255.0
        let a = CGFloat(hex4 & 0xff)/255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }

    // CSS convention: RRGGBBAA
    public convenience init(hex4String: String) {
        var hexInt: UInt64 = 0
        let scanner: Scanner = Scanner(string: hex4String)
        scanner.scanHexInt64(&hexInt)
        let int = Int(hexInt)
        self.init(hex4: int)
    }

    // Display P3 color profile support
    
    public convenience init(p3r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) {
        self.init(displayP3Red: p3r, green: g, blue: b, alpha: a)
    }
    
    public convenience init(p3hex3: Int) {
        let r = CGFloat((p3hex3 >> 16) & 0xff)/255.0
        let g = CGFloat((p3hex3 >> 8) & 0xff)/255.0
        let b = CGFloat(p3hex3 & 0xff)/255.0
        self.init(p3r: r, g, b)
    }

    public convenience init(p3hex3String: String) {
        var hexInt: UInt64 = 0
        let scanner: Scanner = Scanner(string: p3hex3String)
        scanner.scanHexInt64(&hexInt)
        let int = Int(hexInt)
        self.init(p3hex3: int)
    }

    public convenience init(p3hex4: Int) {
        let r = CGFloat((p3hex4 >> 24) & 0xff)/255.0
        let g = CGFloat((p3hex4 >> 16) & 0xff)/255.0
        let b = CGFloat((p3hex4 >> 8) & 0xff)/255.0
        let a = CGFloat(p3hex4 & 0xff)/255.0
        self.init(p3r: r, g, b, a)
    }

    public convenience init(p3hex4String: String) {
        var hexInt: UInt64 = 0
        let scanner: Scanner = Scanner(string: p3hex4String)
        scanner.scanHexInt64(&hexInt)
        let int = Int(hexInt)
        self.init(p3hex4: int)
    }

    //
    
    public static func systemTintColor() -> UIColor {
        return UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
    }
    
    @available(*, deprecated, message: "Use hex3String instead")
    public var hexString: String {
       let components = self.cgColor.components
       let r: CGFloat = components?[0] ?? 0.0
       let g: CGFloat = components?[1] ?? 0.0
       let b: CGFloat = components?[2] ?? 0.0

       let hexString = String.init(format: "%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
       return hexString
    }
    
    @available(*, deprecated, message: "Use UIColor(hex3:) instead")
    public static func colorFromHex(_ hex: Int) -> UIColor {
        let redPart = CGFloat((hex >> 16) & 0xff)/255.0
        let greenPart = CGFloat((hex >> 8) & 0xff)/255.0
        let bluePart = CGFloat(hex & 0xff)/255.0
        return UIColor(red: redPart, green: greenPart, blue: bluePart, alpha: 1.0)
    }

    @available(*, deprecated, message: "Use UIColor(hex3String:) instead")
    public static func colorFromHexStr(_ hexStr: String) -> UIColor {
        var hexInt: UInt64 = 0
        let scanner: Scanner = Scanner(string: hexStr)
        scanner.scanHexInt64(&hexInt)
        let int = Int(hexInt)
        return colorFromHex(int)
    }
}

extension UIView {
    
    public func subviewAt(point: CGPoint) -> UIView? {
        for view in subviews {
            if view.frame.contains(point) {
                return view
            }
        }
        
        return nil
    }
    
    public func rotateTo(angle: CGFloat) {
        let radians = angle / 180.0 * CGFloat(Double.pi)
        self.transform = CGAffineTransform.init(rotationAngle: radians)
    }
    
    public func continuousRotate(duration: CFTimeInterval) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = Float.infinity
        self.layer.add(rotateAnimation, forKey: nil)
    }
    
    public func roundCorners(radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
    }
    
    public func moveX(_ delta: CGFloat) {
        var frame = self.frame
        frame.origin.x += delta
        self.frame = frame
    }
    
    public func moveY(_ delta: CGFloat) {
        var frame = self.frame
        frame.origin.y += delta
        self.frame = frame
    }
    
    public func changeHeight(_ height: CGFloat) {
        var frame = self.frame
        frame.size.height = height
        self.frame = frame
    }
    
    public func changeWidth(_ width: CGFloat) {
        var frame = self.frame
        frame.size.width = width
        self.frame = frame
    }
    
    public func setFrameOrigin(_ newOrigin: CGPoint) {
        var frame = self.frame
        frame.origin = newOrigin
        self.frame = frame
    }
    
    public var firstResponder: UIView? {
        guard !self.isFirstResponder else { return self }
        
        for subview in self.subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }
        
        return nil
    }
    
    public func doIncorrectAttemptShakeAnimation() {
        // shakes the view like macOS's "wrong password" text field shake animation
        self.frame = self.frame.offsetBy(dx: -1.0, dy: 0.0)
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.2, initialSpringVelocity: 1800.0, options: [], animations: {
            self.frame = self.frame.offsetBy(dx: 1.0, dy: 0.0)
        }, completion: nil)
    }
    
    public func doBumpUpAnimation() {
        self.frame = self.frame.offsetBy(dx: 0.0, dy: 1.0)
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 900.0, options: [], animations: {
            self.frame = self.frame.offsetBy(dx: 0.0, dy: -1.0)
        }, completion: nil)
    }
    
    public func doBumpDownAnimation() {
        self.frame = self.frame.offsetBy(dx: 0.0, dy: -1.0)
        UIView.animate(withDuration: 1.0, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 900.0, options: [], animations: {
            self.frame = self.frame.offsetBy(dx: 0.0, dy: 1.0)
        }, completion: nil)
    }
    
    public func doBounceAnimation(dur1: Double = 0.07,
                           dur2: Double = 0.2,
                           scale: CGFloat = 0.85,
                           completion: (()->())? = nil) {
        UIView.animate(withDuration: dur1,
                       delay: 0,
                       usingSpringWithDamping: 0.2,
                       initialSpringVelocity: 12,
                       options: [.allowUserInteraction],
                       animations: {
                        self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }, completion: { _ in
            UIView.animate(withDuration: dur2,
                           delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 6,
                           options: [.allowUserInteraction],
                           animations: {
                            self.transform = CGAffineTransform.identity
            }, completion: { _ in
                completion?()
            })
        })
    }
    
    public func fadeTransition(_ duration:CFTimeInterval) {
        let animation = CATransition()
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.type = .fade
        animation.duration = duration
        self.layer.add(animation, forKey: "fade")
    }
    
    public func doFlyToViewBumpAnimation(toView: UIView) {
        guard let superview = superview,
            let containerView = superview.window?.rootViewController?.view,
            let toViewScreenRect = toView.superview?.convert(toView.frame, to: nil)
            else { return }
        let viewImage = UIImage.imageFromView(self)
        let imageView = UIImageView(image: viewImage)
        
        let startScreenRect = superview.convert(frame, to: nil)
        let endScreenRect = CGRect(x: toViewScreenRect.midX, y: toViewScreenRect.midY, width: 20, height: 20)
        
        containerView.addSubview(imageView)
        imageView.frame = startScreenRect
        imageView.alpha = 1.0
        
        UIView.animate(withDuration: 0.5, delay: 0.0, options: [.curveEaseIn, .allowUserInteraction], animations: {
            imageView.frame = endScreenRect
            imageView.alpha = 0.5

        }) { (animated) in
            imageView.removeFromSuperview()
            toView.doBumpDownAnimation()
        }
                
    }
}

extension UIViewController {
    public func addAsChild(parentVC: UIViewController, containerView: UIView) {
        parentVC.addChild(self)
        let view = self.view!.forAutoLayout()
        containerView.addSubview(view)
        view.constrainToSuperviewEdges()
        self.didMove(toParent: parentVC)
    }
    public func removeChildFromParent() {
        self.willMove(toParent: nil)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    public func createNoTextBackButton() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    // When the keyboard appears, use this if a certain view (like a Continue button) needs to be visible. Do not call within the keyboardWillShow animation block.
    public func scrollViewToVisible(scrollView: UIScrollView, kbdHeight: CGFloat, targetView: UIView, padding: CGFloat = 0) {
        var visibleFrame = view.frame
        visibleFrame.size.height -= kbdHeight
        
        var targetFrame = targetView.frame
        targetFrame.size.height += 2 * padding
        targetFrame.origin.y -= padding
        
        let convertedTargetFrame = view.superview!.convert(targetFrame, from: targetView.superview!)
        
        if !visibleFrame.contains(convertedTargetFrame) {
            let convertedTargetFromForScroll = scrollView.superview!.convert(targetFrame, from: targetView.superview!)
            scrollView.scrollRectToVisible(convertedTargetFromForScroll, animated: true)
        }
    }

    public func present(_ vc: UIViewController, customTransition: CATransitionType, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        guard let window = self.view.window else {
            return
        }
        let transition = CATransition()
        transition.duration = duration
        transition.type = customTransition
        window.layer.add(transition, forKey: nil)
        self.present(vc, animated: false, completion: completion)
    }
    public func dismiss(customTransition: CATransitionType, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        guard let window = self.view.window else {
            Logger.log("*** no window"); completion?(); return
        }
        let transition = CATransition()
        transition.duration = duration
        transition.type = customTransition
        window.layer.add(transition, forKey: nil)
        self.dismiss(animated: false, completion: completion)
    }
}

extension UIScrollView {    
    public func scrollToView(view: UIView, animated: Bool = false) {
        var childStartRect = view.convert(view.bounds, to: self)
        childStartRect.size.height += 90 // extra padding so view isn't right at the edge of the scroll view's top or bottom
        childStartRect.origin.y -= 40
        
        if childStartRect.size.height > visibleSize.height {
            childStartRect.size.height = visibleSize.height - 40
        }
        // Scroll to a rectangle starting at the Y of your subview, with a height of the scrollview
        if let noAutoScrollingScrollView = self as? NoAutoScrollingScrollView {
            noAutoScrollingScrollView.reallyScrollRectToVisible(childStartRect, animated: animated)
        } else {
            self.scrollRectToVisible(childStartRect, animated: animated)
        }
    }
    
    public func recenterForScale(_ scale: CGFloat) {
        // Keep the scroll content centered while zooming or resizing. This is worked out by seeing that while scaling the graph, the viewable area (scrollView.bounds) remains fixed while the total width (scrollView.contentSize) and offset (scrollView.contentOffset) change. We can keep the center fixed by scaling the content offset with a fixed ratio, where the ratio is:
        //
        // r = offset / (contentWidth - boundsWidth)
        //
        // We then calculate the new totalWidth by multiplying by the new scale and solve for offset:
        //
        // newContentWidth = offset * scale
        // newOffset = r * (newContentWidth - boundsWidth)
        //

        if scale != 1.0 && contentSize.width != bounds.width {
            let oldOffset = contentOffset.x
            let ratio = oldOffset / (contentSize.width - bounds.width)
            let newContentW = contentSize.width * scale
            let newOffset = ratio * (newContentW - bounds.width)
            contentOffset = CGPoint(x: newOffset, y: contentOffset.y)
        }
    }
}

extension UINavigationController {
    public func makeTransparent() {
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
    }
    
    public func pushViewController(_ viewController: UIViewController, customTransition: CATransitionType, duration: TimeInterval = 0.3) {
        let transition = CATransition()
        transition.duration = duration
        transition.type = customTransition
        self.view.layer.add(transition, forKey: nil)
        self.pushViewController(viewController, animated: false)
    }
    @discardableResult public func popViewController(customTransition: CATransitionType, duration: TimeInterval = 0.3) -> UIViewController? {
        let transition = CATransition()
        transition.duration = duration
        transition.type = customTransition
        self.view.layer.add(transition, forKey: nil)
        return self.popViewController(animated: false)
    }
    @discardableResult public func popToViewController(_ viewController: UIViewController, customTransition: CATransitionType, duration: TimeInterval = 0.3) -> [UIViewController]? {
        let transition = CATransition()
        transition.duration = duration
        transition.type = customTransition
        self.view.layer.add(transition, forKey: nil)
        return self.popToViewController(viewController, animated: false)
    }
}

extension UITextField {
    public var isEmpty: Bool {
        return self.text.nonNil.isEmpty
    }
}

extension UITabBar {
    public func orderedTabBarItemViews() -> [UIView] {
        let interactionViews = subviews.filter({$0.isUserInteractionEnabled})
        return interactionViews.sorted(by: {$0.frame.minX < $1.frame.minX})
    }
}

extension UIImageView {
    public func makeTintable() {
        self.image = self.image?.withRenderingMode(.alwaysTemplate)
    }
    public func setImage(_ image: UIImage?, animatingWithDuration: TimeInterval) {
        DispatchQueue.main.async {
            UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.image = image
            }, completion: nil)
        }
    }
}

extension UILabel {
    @IBInspectable public var kerning: CGFloat {
        get {
            var range = NSMakeRange(0, (text ?? "").count)
            guard let kern = attributedText?.attribute(.kern, at: 0, effectiveRange: &range),
                let value = kern as? NSNumber
                else {
                    return 0
            }
            return CGFloat(value.floatValue)
        }
        set {
            var attText:NSMutableAttributedString
            
            if let attributedText = attributedText {
                attText = NSMutableAttributedString(attributedString: attributedText)
            } else if let text = text {
                attText = NSMutableAttributedString(string: text)
            } else {
                attText = NSMutableAttributedString(string: "")
            }
            
            let range = NSMakeRange(0, attText.length)
            attText.addAttribute(.kern, value: NSNumber(value: Float(newValue)), range: range)
            self.attributedText = attText
        }
    }
    
    public func heightForWidth(_ width: CGFloat) -> CGFloat {
        let boundingBox = self.attributedText!.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        return boundingBox.height
    }
}

extension UITextView {
    public func heightForWidth(_ width: CGFloat) -> CGFloat {
        let boundingBox = self.attributedText!.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        return boundingBox.height
    }
}

extension UIImage {
    
    public class func imageFromView(_ view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    
    public func resize(to newSize: CGSize) -> UIImage? {
        guard self.size != newSize else { return self }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))

        defer { UIGraphicsEndImageContext() }
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    public func pixelBuffer() -> CVPixelBuffer? {

        let width = Int(self.size.width)
        let height = Int(self.size.height)

        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData, width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }

        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }
    
    // uses "aspect fit"
    public func resize(targetSizePx: CGSize) -> UIImage? {
        let size = self.size
        
        let widthRatio  = targetSizePx.width  / self.size.width
        let heightRatio = targetSizePx.height / self.size.height
        var newSize: CGSize
        
        if widthRatio > heightRatio {
            newSize = CGSize(width: floor(size.width * heightRatio), height: floor(size.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(size.width * widthRatio),  height: floor(size.height * widthRatio))
        }
        
        newSize.width /= self.scale
        newSize.height /= self.scale
        
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    public func resample(bpc: Int) -> UIImage? {
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
    public func fixOrientation() -> UIImage {
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
    
    public class func image(with color: UIColor) -> UIImage {
        let rect = CGRect(origin: CGPoint(x: 0, y:0), size: CGSize(width: 1, height: 1))
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!.resizableImage(withCapInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
    }
    
    
    public func sizePxForMaxSide(_ maxSide: CGFloat) -> CGSize {
        var sizePx = self.size
        sizePx.width *= self.scale
        sizePx.height *= self.scale
        
        // If we're already smaller than max on both sides, return current size in px.
        if max(sizePx.width, sizePx.height) < maxSide {
            return size
        }
        
        let widthRatio  = maxSide  / self.size.width
        let heightRatio = maxSide / self.size.height
        var newSize: CGSize
        
        if widthRatio > heightRatio {
            newSize = CGSize(width: floor(sizePx.width * heightRatio), height: floor(sizePx.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(sizePx.width * widthRatio),  height: floor(sizePx.height * widthRatio))
        }
        
        return newSize
    }
    
    public func crop(rect: CGRect) -> UIImage {
        let fixedImage = self.fixOrientation()
        let imageRef = fixedImage.cgImage!.cropping(to: rect)
        let image = UIImage(cgImage: imageRef!, scale: fixedImage.scale, orientation: fixedImage.imageOrientation)
        return image
    }
    
    public func crop(aspect: CGFloat) -> UIImage {
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
    
    public func rectOfCrop(toAspect aspect: CGFloat) -> CGRect {
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

    public func applyingBorder(color: UIColor, size: CGFloat) -> UIImage {
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
    
    public func getUnderlyingData() -> Data? {
        if let dataProvider = self.cgImage?.dataProvider, let underlyingData = dataProvider.data as Data? {
            return underlyingData
        } else {
            return nil
        }
    }

}

extension UIEdgeInsets {
    mutating public func offset(by offset: UIEdgeInsets) {
        top -= offset.top
        left -= offset.left
        bottom -= offset.bottom
        right -= offset.right
    }
}

extension UIStackView {
    public func removeAllArrangedSubviews() {
        for view in self.arrangedSubviews {
            self.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}

extension UITableView {
    public func safeSelect(at path: IndexPath, animated: Bool, scrollPosition: UITableView.ScrollPosition, notify: Bool = false) {
        let numRows = self.numberOfRows(inSection: path.section)
        if path.row < numRows {
            self.selectRow(at: path, animated: animated, scrollPosition: scrollPosition)
            if notify {
                self.delegate?.tableView?(self, didSelectRowAt: path)
            }
        } else {
            assertionFailure()
            Logger.fileLog("*** path out of bounds: \(path). row cnt: \(numRows)")
        }
    }
}

public class AlwaysPopover : NSObject, UIPopoverPresentationControllerDelegate {
    // Use this to force a popover on an iPhone in portrait mode. Without it, your vc will display in full screen.
    static let shared = AlwaysPopover()
    
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }    
}

// this subclass sets the intrinsic content size to be the height of *all* the table view rows. best used when disabling scrolling on the table view also.
public class FixedHeightTableView: UITableView {
    public override func layoutSubviews() {
        super.layoutSubviews()
        self.invalidateIntrinsicContentSize()
    }
    
    public override var intrinsicContentSize: CGSize {
        var height = CGFloat(0.0)
        if self.numberOfSections > 0 {
            for section in 0...self.numberOfSections-1 {
                for row in 0...self.numberOfRows(inSection: section) {
                    height += self.rectForRow(at: IndexPath(row: row, section: section)).size.height
                }
            }
        }
        return CGSize(width: super.intrinsicContentSize.width, height: height)
    }
    
    public override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
}


// This subclass prevents the UIScrollView from auto-scrolling itself when things like UITextField are selected (we manage it ourselves). See:
// https://stackoverflow.com/questions/4585718/disable-uiscrollview-scrolling-when-uitextfield-becomes-first-responder
public class NoAutoScrollingScrollView: UIScrollView {
    public func reallyScrollRectToVisible(_ rect: CGRect, animated: Bool) {
        super.scrollRectToVisible(rect, animated: animated)
    }
    
    public override func scrollRectToVisible(_ rect: CGRect, animated: Bool) {
        return
    }
}
