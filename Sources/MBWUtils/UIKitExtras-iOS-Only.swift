//
//  UIKitExtras-iOS-Only.swift
//  MBWUtils
//
//  Created by John Scalo on 1/23/25.
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
    
    var firstSceneStatusBarFrame: CGRect? {
        if #available(iOS 13.0, *) {
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
            return windowScene?.statusBarManager?.statusBarFrame
        } else {
            return UIApplication.shared.statusBarFrame
        }
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
    
    /// Given some height, compute the width as determined by autolayout constraints. Useful if the view hasn't been rendered on-screen yet. (NB: this variant hasn't been tested; `autolayoutHeight` has.)
    func autolayoutWidth(for height: CGFloat) -> CGFloat {
        let targetSize = CGSize(
            width: UIView.layoutFittingCompressedSize.width,
            height: height)
        let computedSize = systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .fittingSizeLevel,
            verticalFittingPriority: .required)
        return computedSize.width
    }

    /// Given some width, compute the height as determined by autolayout constraints. Useful if the view hasn't been rendered on-screen yet.
    func autolayoutHeight(for width: CGFloat) -> CGFloat {
        let targetSize = CGSize(
            width: width,
            height: UIView.layoutFittingCompressedSize.height)
        let computedSize = systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel)
        return computedSize.height
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
    
    // Using the name `present` works but can lead to collisions later if caller wants to call the non-async version in an async context.
    @available(iOS 13.0, *)
    func presentAsync(_ viewControllerToPresent: UIViewController, customTransition: CATransitionType? = nil, duration: TimeInterval = 0.3, animated flag: Bool = true) async {
        await withCheckedContinuation { continuation in
            if let customTransition {
                self.present(viewControllerToPresent, customTransition: customTransition, duration: duration) {
                    continuation.resume()
                }
            } else {
                self.present(viewControllerToPresent, animated: flag) {
                    continuation.resume()
                }
            }
        }
    }
    
    // Using the name `dismiss` works but can lead to collisions later if caller wants to call the non-async version in an async context.
    @available(iOS 13.0, *)
    func dismissAsync(customTransition: CATransitionType? = nil, duration: TimeInterval = 0.3, animated flag: Bool = true) async {
        await withCheckedContinuation { continuation in
            if let customTransition {
                self.dismiss(customTransition: customTransition, duration: duration) {
                    continuation.resume()
                }
            } else {
                self.dismiss(animated: flag) {
                    continuation.resume()
                }
            }
        }
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

public extension UIImage {
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
}

public extension UIFont {
    func asSFRounded() -> UIFont {
        if #available(iOS 13.0, *) {
            let fontSize = self.pointSize
            let weight = self.fontDescriptor.symbolicTraits.contains(.traitBold) ? UIFont.Weight.bold : UIFont.Weight.regular
            let systemFont = UIFont.systemFont(ofSize: fontSize, weight: weight)

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

#endif // os(iOS)
