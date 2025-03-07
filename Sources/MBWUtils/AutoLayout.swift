//
//  AutoLayout.swift
//
//  Created by John Scalo on 2/16/18.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

#if os(iOS)
import UIKit
public typealias CocoaView = UIView
public typealias EdgeInsets = UIEdgeInsets
#elseif os(OSX)
import AppKit
public typealias CocoaView = NSView
public typealias EdgeInsets = NSEdgeInsets
#endif

#if os(iOS) || os(OSX)
public extension CocoaView {
    
    // Auto layout convenience:
    func autoResizeTranslationCheck() {
        if self.translatesAutoresizingMaskIntoConstraints {
            print("*** Warning: This view has translatesAutoresizingMaskIntoConstraints set yet is trying to do autolayout stuff.")
        }
    }
    @discardableResult func forAutoLayout() -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        return self
    }
    @discardableResult func constrainWidth(_ w: CGFloat, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: w)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainHeight(_ h: CGFloat, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: h)
        c.isActive = activate
        return c
    }
    func constrainSizeTo(view: CocoaView) {
        self.autoResizeTranslationCheck()
        self.heightAnchor.constraint(equalTo: view.heightAnchor, constant: 0).isActive = true
        self.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 0).isActive = true
    }
    
    func constrainToSuperviewEdges(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false) {
        self.autoResizeTranslationCheck()
        self.constrainToEdgesOf(self.superview!, offset: offset, activate: activate, useSafeArea: useSafeArea)
    }

    func constrainToEdgesOf(_ view: CocoaView, offset:CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false) {
        self.autoResizeTranslationCheck()
        self.leftAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.leftAnchor : view.leftAnchor, constant: offset).isActive = activate
        self.rightAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.rightAnchor : view.rightAnchor, constant: offset * -1).isActive = activate
        self.bottomAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor, constant: offset * -1).isActive = activate
        self.topAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor, constant: offset).isActive = activate
    }

    // MARK: - Constraining with edge insets
    
    func constrainToSuperviewEdges(using insets: EdgeInsets, activate: Bool = true, useSafeArea: Bool = false) {
        self.autoResizeTranslationCheck()
        self.constrainToEdgesOf(self.superview!, using: insets, activate: activate, useSafeArea: useSafeArea)
    }
    
    func constrainToEdgesOf(_ view: CocoaView, using insets: EdgeInsets, activate: Bool = true, useSafeArea: Bool = false) {
        self.autoResizeTranslationCheck()
        #if !os(iOS)
        if useSafeArea {
            assertionFailure("safeAreaLayoutGuide not supported on macOS")
            return
        }
        #endif
        self.leftAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.leftAnchor : view.leftAnchor, constant: insets.left).isActive = true
        self.rightAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.rightAnchor : view.rightAnchor, constant: -insets.right).isActive = true
        self.bottomAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor, constant: -insets.bottom).isActive = true
        self.topAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor, constant: insets.top).isActive = true
    }

    // While technically correct, these are confusing because the right and bottom insets are reversed from what you'd expect them to be, so now deprecated.
    @available(*, deprecated, message: "Use constrainToSuperviewEdges(using:) instead.")
    func constrainToSuperviewEdges(with insets: EdgeInsets, activate: Bool = true, useSafeArea: Bool = false) {
        self.autoResizeTranslationCheck()
        self.constrainToEdgesOf(self.superview!, with: insets, activate: activate, useSafeArea: useSafeArea)
    }
    @available(*, deprecated, message: "Use constrainToEdgesOf(using:) instead.")
    func constrainToEdgesOf(_ view: CocoaView, with insets: EdgeInsets, activate: Bool = true, useSafeArea: Bool = false) {
        self.autoResizeTranslationCheck()
        #if !os(iOS)
        if useSafeArea {
            assertionFailure("safeAreaLayoutGuide not supported on macOS")
            return
        }
        #endif
        self.leftAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.leftAnchor : view.leftAnchor, constant: insets.left).isActive = true
        self.rightAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.rightAnchor : view.rightAnchor, constant: insets.right).isActive = true
        self.bottomAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.bottomAnchor : view.bottomAnchor, constant: insets.bottom).isActive = true
        self.topAnchor.constraint(equalTo: useSafeArea ? view.safeAreaLayoutGuide.topAnchor : view.topAnchor, constant: insets.top).isActive = true
    }

    // MARK: -
    
    @discardableResult func constrainToSuperviewLeading(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false, useMargin: Bool = false) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.leadingAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.leadingAnchor, constant: offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else if useMargin {
            #if os(iOS)
            c = self.leadingAnchor.constraint(equalTo: self.superview!.layoutMarginsGuide.leadingAnchor, constant: offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("layoutMarginsGuide not supported on macOS")
            #endif
        } else {
            c = self.leadingAnchor.constraint(equalTo: self.superview!.leadingAnchor, constant: offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToSuperviewLeft(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false, useMargin: Bool = false) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.leftAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.leftAnchor, constant: offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else if useMargin {
            #if os(iOS)
            c = self.leftAnchor.constraint(equalTo: self.superview!.layoutMarginsGuide.leftAnchor, constant: offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("layoutMarginsGuide not supported on macOS")
            #endif
        } else {
            c = self.leftAnchor.constraint(equalTo: self.superview!.leftAnchor, constant: offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToSuperviewTrailing(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false, useMargin: Bool = false) -> NSLayoutConstraint {
        // NB: offset is negated to be more intuitive
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.trailingAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.trailingAnchor, constant: -offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else if useMargin {
            #if os(iOS)
            c = self.trailingAnchor.constraint(equalTo: self.superview!.layoutMarginsGuide.trailingAnchor, constant: -offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("layoutMarginsGuide not supported on macOS")
            #endif
        } else {
            c = self.trailingAnchor.constraint(equalTo: self.superview!.trailingAnchor, constant: -offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToSuperviewRight(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false, useMargin: Bool = false) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.rightAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.rightAnchor, constant: -offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else if useMargin {
            #if os(iOS)
            c = self.rightAnchor.constraint(equalTo: self.superview!.layoutMarginsGuide.rightAnchor, constant: -offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("layoutMarginsGuide not supported on macOS")
            #endif
        } else {
            c = self.rightAnchor.constraint(equalTo: self.superview!.rightAnchor, constant: -offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToSuperviewTop(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false, useMargin: Bool = false) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.topAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.topAnchor, constant: offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else if useMargin {
            #if os(iOS)
            c = self.topAnchor.constraint(equalTo: self.superview!.layoutMarginsGuide.topAnchor, constant: offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("layoutMarginsGuide not supported on macOS")
            #endif
        } else {
            c = self.topAnchor.constraint(equalTo: self.superview!.topAnchor, constant: offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToSuperviewBottom(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false, useMargin: Bool = false) -> NSLayoutConstraint {
        // NB: offset is negated to be more intuitive
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.bottomAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.bottomAnchor, constant: -offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else if useMargin {
            #if os(iOS)
            c = self.bottomAnchor.constraint(equalTo: self.superview!.layoutMarginsGuide.bottomAnchor, constant: -offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("layoutMarginsGuide not supported on macOS")
            #endif
        } else {
            c = self.bottomAnchor.constraint(equalTo: self.superview!.bottomAnchor, constant: -offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToSuperviewXCenter(offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = self.centerXAnchor.constraint(equalTo: self.superview!.centerXAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToSuperviewYCenter(offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = self.centerYAnchor.constraint(equalTo: self.superview!.centerYAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToSuperviewYCenter(multiplier: CGFloat) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: self.superview, attribute: .centerY, multiplier: multiplier, constant: 0)
        c.isActive = true
        return c
    }
    @discardableResult func constrainToXCenterOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToYCenterOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = self.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToTopOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.topAnchor.constraint(equalTo: self.bottomAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainTopToTopOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.topAnchor.constraint(equalTo: self.topAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainTopToBottomOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        // NB: offset is negated to be more intuitive
        self.autoResizeTranslationCheck()
        let c = view.bottomAnchor.constraint(equalTo: self.topAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainBottomToBottomOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainBottomToTopOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.topAnchor.constraint(equalTo: self.bottomAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToLeadingOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainLeadingToLeadingOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -offset)
        if activate {
            c.isActive = activate
        }
        return c
    }
    @discardableResult func constrainLeadingToTrailingOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.trailingAnchor.constraint(equalTo: self.leadingAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainLeftToRightOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.rightAnchor.constraint(equalTo: self.leftAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainTrailingToLeadingOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainToTrailingOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.trailingAnchor.constraint(equalTo: self.leadingAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainTrailingToTrailingOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainWidthEqualTo(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.widthAnchor.constraint(equalTo: self.widthAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func constrainHeightEqualTo(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.heightAnchor.constraint(equalTo: self.heightAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func alignBottomToBottomOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult func alignBottomToTopOf(_ view: CocoaView, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.topAnchor.constraint(equalTo: self.bottomAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    
    /// Constrain the view's aspect ratio, where the provided ratio = width / height.
    @discardableResult func constrainAspectRatio(_ a: CGFloat) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: a)
        c.isActive = true
        return c
    }
}

public extension NSLayoutConstraint {
    // Use with care. But there are legit scenarios where layout warnings are benign, notably when there's a bunch of incoming constraints that might conflict serially but not as a batch.
    static func setWarningsEnabled(_ enabled: Bool) {
        UserDefaults.standard.setValue(enabled, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }
}
#endif

/// Computes a linearly interpolated value between `minY` and `maxY` based on `val` within the range `minX` to `maxX`, then clamps the result between `minY` and `maxY`.
///
/// Can be useful for dynamically adjusting view constraints proportionally. In this context:
/// - minX: a minimum screen/view width/height
/// - maxX: a maximum screen/view width/height
/// - minY: lower bound of possible output values
/// - maxY: upper bound of possible output values
/// - val: the actual screen/view width/height
public func clampLinear<T: BinaryFloatingPoint>(_ minX: T, _ maxX: T, _ minY: T, _ maxY: T, _ val: T) -> T {
    let slope = (maxY - minY) / (maxX - minX)
    let interpolated = minY + slope * (val - minX)
    return clamp(minY, interpolated, maxY)
}
public func clamp<T: Comparable>(_ minValue: T, _ val: T, _ maxValue: T) -> T {
    return max(minValue, min(val, maxValue))
}
