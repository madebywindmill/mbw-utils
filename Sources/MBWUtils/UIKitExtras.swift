//
//  UIKitExtras.swift
//
//  Created by John Scalo on 12/21/17.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

#if os(iOS)

import UIKit
import CoreServices

public extension UIApplication {
    var icon: UIImage? {
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
    
    var sceneKeyWindow: UIWindow? {
        return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
    }
    
    var sceneKeyViewController: UIViewController? {
        return sceneKeyWindow?.rootViewController
    }
}

public class SFSymbolsFixButton: UIButton {
    public override func awakeFromNib() {
        super.awakeFromNib()
        fixScalingIssueWithSFSymbols()
    }
}

public extension UIDevice {
    var modelID: String {
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

public extension UIButton {
    func fixScalingIssueWithSFSymbols() {
        imageView?.contentMode = .scaleAspectFit
    }
    
    func setTitle(_ title: String?, for state: UIControl.State, animated: Bool = false) {
        if !animated {
            UIView.setAnimationsEnabled(false)
        }
        
        setTitle(title, for: state)
        
        if !animated {
            UIView.setAnimationsEnabled(true)
        }
    }
    
    func setAttributedTitle(_ title: NSAttributedString?, for state: UIControl.State, animated: Bool = false) {
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

public extension UIFont {
    var weight: UIFont.Weight {
        guard let weightNumber = traits[.weight] as? NSNumber else { return .regular }
        let weightRawValue = CGFloat(weightNumber.doubleValue)
        let weight = UIFont.Weight(rawValue: weightRawValue)
        return weight
    }

    var traits: [UIFontDescriptor.TraitKey: Any] {
        return fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any]
            ?? [:]
    }
    
    func with(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        return UIFont(descriptor: self.fontDescriptor.withSymbolicTraits(traits)!, size: self.pointSize)
    }

    func asSFRounded() -> UIFont {
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

public extension UIView {
    
    convenience init(backgroundColor: UIColor) {
        self.init()
        self.backgroundColor = backgroundColor
    }
    
    func subviewAt(point: CGPoint) -> UIView? {
        for view in subviews {
            if view.frame.contains(point) {
                return view
            }
        }
        
        return nil
    }
    
    func rotateTo(angle: CGFloat) {
        let radians = angle / 180.0 * CGFloat(Double.pi)
        self.transform = CGAffineTransform.init(rotationAngle: radians)
    }
    
    func continuousRotate(duration: CFTimeInterval) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2)
        rotateAnimation.isRemovedOnCompletion = false
        rotateAnimation.duration = duration
        rotateAnimation.repeatCount = Float.infinity
        self.layer.add(rotateAnimation, forKey: nil)
    }
    
    func roundCorners(radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
    }
    
    func moveX(_ delta: CGFloat) {
        var frame = self.frame
        frame.origin.x += delta
        self.frame = frame
    }
    
    func moveY(_ delta: CGFloat) {
        var frame = self.frame
        frame.origin.y += delta
        self.frame = frame
    }
    
    func changeHeight(_ height: CGFloat) {
        var frame = self.frame
        frame.size.height = height
        self.frame = frame
    }
    
    func changeWidth(_ width: CGFloat) {
        var frame = self.frame
        frame.size.width = width
        self.frame = frame
    }
    
    func setFrameOrigin(_ newOrigin: CGPoint) {
        var frame = self.frame
        frame.origin = newOrigin
        self.frame = frame
    }
    
    var firstResponder: UIView? {
        guard !self.isFirstResponder else { return self }
        
        for subview in self.subviews {
            if let firstResponder = subview.firstResponder {
                return firstResponder
            }
        }
        
        return nil
    }
    
    func recursiveSubviews() -> [UIView] {
        var views = [UIView]()
        views.append(self)
        for next in subviews {
            views += next.recursiveSubviews()
        }
        return views
    }
}

public extension UIViewController {
    
    var statusBarSize: CGSize {
        if #available(iOS 13.0, *) {
            guard let sbm = view.window?.windowScene?.statusBarManager else {
                return CGSize.zero
            }
            return sbm.statusBarFrame.size
        } else {
            return UIApplication.shared.statusBarFrame.size
        }
    }
    
    func addAsChild(parentVC: UIViewController, containerView: UIView) {
        parentVC.addChild(self)
        let view = self.view!.forAutoLayout()
        containerView.addSubview(view)
        view.constrainToSuperviewEdges()
        self.didMove(toParent: parentVC)
    }
    func removeChildFromParent() {
        self.willMove(toParent: nil)
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    func createNoTextBackButton() {
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    // When the keyboard appears, use this if a certain view (like a Continue button) needs to be visible. Do not call within the keyboardWillShow animation block.
    func scrollViewToVisible(scrollView: UIScrollView, kbdHeight: CGFloat, targetView: UIView, padding: CGFloat = 0) {
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

    func present(_ vc: UIViewController, customTransition: CATransitionType, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
        guard let window = self.view.window else {
            return
        }
        let transition = CATransition()
        transition.duration = duration
        transition.type = customTransition
        window.layer.add(transition, forKey: nil)
        self.present(vc, animated: false, completion: completion)
    }
    func dismiss(customTransition: CATransitionType, duration: TimeInterval = 0.3, completion: (() -> Void)? = nil) {
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

public extension UIScrollView {
    func scrollToView(view: UIView, animated: Bool = false) {
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
    
    func recenterForScale(_ scale: CGFloat) {
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

public extension UINavigationController {
    func makeTransparent() {
        self.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationBar.shadowImage = UIImage()
    }
    
    func pushViewController(_ viewController: UIViewController, customTransition: CATransitionType, duration: TimeInterval = 0.3) {
        let transition = CATransition()
        transition.duration = duration
        transition.type = customTransition
        self.view.layer.add(transition, forKey: nil)
        self.pushViewController(viewController, animated: false)
    }
    @discardableResult func popViewController(customTransition: CATransitionType, duration: TimeInterval = 0.3) -> UIViewController? {
        let transition = CATransition()
        transition.duration = duration
        transition.type = customTransition
        self.view.layer.add(transition, forKey: nil)
        return self.popViewController(animated: false)
    }
    @discardableResult func popToViewController(_ viewController: UIViewController, customTransition: CATransitionType, duration: TimeInterval = 0.3) -> [UIViewController]? {
        let transition = CATransition()
        transition.duration = duration
        transition.type = customTransition
        self.view.layer.add(transition, forKey: nil)
        return self.popToViewController(viewController, animated: false)
    }
}

public extension UITextField {
    var isEmpty: Bool {
        return self.text.nonNil.isEmpty
    }
}

public extension UITabBar {
    func orderedTabBarItemViews() -> [UIView] {
        let interactionViews = subviews.filter({$0.isUserInteractionEnabled})
        return interactionViews.sorted(by: {$0.frame.minX < $1.frame.minX})
    }
}

public extension UIImageView {
    func makeTintable() {
        self.image = self.image?.withRenderingMode(.alwaysTemplate)
    }
    func setImage(_ image: UIImage?, animatingWithDuration: TimeInterval) {
        mainAsync {
            UIView.transition(with: self, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.image = image
            }, completion: nil)
        }
    }
}

public extension UILabel {
    @IBInspectable var kerning: CGFloat {
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

    @IBInspectable var lineHeightMultiple: CGFloat {
        get {
            var range = NSMakeRange(0, (text ?? "").count)
            guard let ps = attributedText?.attribute(.paragraphStyle, at: 0, effectiveRange: &range) as? NSParagraphStyle else {
                    return 0
            }
            return CGFloat(ps.lineHeightMultiple)
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
            
            var pStyle = attributedText?.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSMutableParagraphStyle
            if pStyle == nil {
                pStyle = NSMutableParagraphStyle()
            }
            pStyle!.lineHeightMultiple = newValue
            let range = NSMakeRange(0, attText.length)
            attText.addAttribute(.paragraphStyle, value: pStyle!, range: range)
            self.attributedText = attText
        }
    }

    func heightForWidth(_ width: CGFloat) -> CGFloat {
        let boundingBox = self.attributedText!.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        return boundingBox.height
    }
}

public extension UITextView {
    func heightForWidth(_ width: CGFloat) -> CGFloat {
        let boundingBox = self.attributedText!.boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude), options: .usesLineFragmentOrigin, context: nil)
        return boundingBox.height
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

    /// Render a bitmap from the provided view and all its subviews. Also see UIView.snapshotView() and CALayer.render() both of which are probably faster.
    class func imageFromView(_ view: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        defer { UIGraphicsEndImageContext() }
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
    
    func pixelBuffer() -> CVPixelBuffer? {
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
        draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
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

public extension UIStackView {
    func removeAllArrangedSubviews() {
        for view in self.arrangedSubviews {
            self.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}

public extension UITableView {
    func safeSelect(at path: IndexPath, animated: Bool, scrollPosition: UITableView.ScrollPosition, notify: Bool = false) {
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



public extension UIPasteboard {
    
    /// Confusingly UIPasteboard offers several ways to get strings off the clipboard and in many cases one works while others don't. This convenience  pretty much tries all of them, preferring to return a UTF-8 string when possible.
    var plainText: String? {
        guard hasStrings else {
            return nil
        }
        
        if let str = string {
            return str
        } else if let str = strings?.first {
            return str
        } else if let data = data(forPasteboardType: "public.utf8-plain-text"), let str = String(data: data, encoding: .utf8) {
            return str
        } else if let data = data(forPasteboardType: "public.utf16-external-plain-text"), let str = String(data: data, encoding: .utf16) {
            return str
        } else if let data = data(forPasteboardType: "public.utf16-plain-text"), let str = String(data: data, encoding: .utf16) {
            return str
        } else if let data = data(forPasteboardType: "public.text"), let str = String(data: data, encoding: .utf8) {
            return str
        } else if let data = data(forPasteboardType: "public.plain-text"), let str = String(data: data, encoding: .utf8) {
            return str
        } else if let data = data(forPasteboardType: "public.html"), let str = String(data: data, encoding: .utf8) {
            return str
        } else if let data = data(forPasteboardType: "public.xml"), let str = String(data: data, encoding: .utf8) {
            return str
        } else if let data = data(forPasteboardType: "public.xhtml"), let str = String(data: data, encoding: .utf8) {
            return str
        } else if let data = data(forPasteboardType: kUTTypeURL as String), let str = String(data: data, encoding: .utf8) {
            return str
        } else {
            print("Warning: no strings found when strings were promised.")
            return nil
        }
    }
}

#endif

public enum DiffableDatasourceGenericSection: Int {
    case main = 0
}
