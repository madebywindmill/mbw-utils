//
//  MBWAutoLayout.swift
//
//  Created by John Scalo on 2/16/18.
//  Copyright © 2018-2021 Made by Windmill. All rights reserved.
//

#if os(iOS)
import UIKit
public typealias View = UIView
#else // os(OSX)
import AppKit
public typealias View = NSView
#endif

extension View {
    
    // Auto layout convenience:
    public func autoResizeTranslationCheck() {
        if self.translatesAutoresizingMaskIntoConstraints {
            print("*** Warning: This view has translatesAutoresizingMaskIntoConstraints set yet is trying to do autolayout stuff.")
        }
    }
    @discardableResult public func forAutoLayout() -> Self {
        self.translatesAutoresizingMaskIntoConstraints = false
        return self
    }
    @discardableResult public func constrainWidth(_ w: CGFloat, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = NSLayoutConstraint(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: w)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainHeight(_ h: CGFloat, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: h)
        c.isActive = activate
        return c
    }
    public func constrainSizeTo(view: View) {
        self.autoResizeTranslationCheck()
        self.heightAnchor.constraint(equalTo: view.heightAnchor, constant: 0).isActive = true
        self.widthAnchor.constraint(equalTo: view.widthAnchor, constant: 0).isActive = true
    }
    public func constrainToSuperviewEdges(offset: CGFloat = 0, activate: Bool = true) {
        self.autoResizeTranslationCheck()
        self.constrainToEdgesOf(self.superview!, offset: offset, activate: activate)
    }
    public func constrainToEdgesOf(_ view: View, offset:CGFloat = 0, activate: Bool = true) {
        self.autoResizeTranslationCheck()
        self.leftAnchor.constraint(equalTo: view.leftAnchor, constant: offset).isActive = activate
        self.rightAnchor.constraint(equalTo: view.rightAnchor, constant: offset * -1).isActive = activate
        self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: offset * -1).isActive = activate
        self.topAnchor.constraint(equalTo: view.topAnchor, constant: offset).isActive = activate
    }
    @discardableResult public func constrainToSuperviewLeading(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.leadingAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.leadingAnchor, constant: offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else {
            c = self.leadingAnchor.constraint(equalTo: self.superview!.leadingAnchor, constant: offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToSuperviewLeft(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.leftAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.leftAnchor, constant: offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else {
            c = self.leftAnchor.constraint(equalTo: self.superview!.leftAnchor, constant: offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToSuperviewTrailing(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false) -> NSLayoutConstraint {
        // NB: offset is negated to be more intuitive
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.trailingAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.trailingAnchor, constant: -offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else {
            c = self.trailingAnchor.constraint(equalTo: self.superview!.trailingAnchor, constant: -offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToSuperviewRight(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false) -> NSLayoutConstraint {
        // NB: offset is negated to be more intuitive
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.rightAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.rightAnchor, constant: -offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else {
            c = self.rightAnchor.constraint(equalTo: self.superview!.rightAnchor, constant: -offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToSuperviewTop(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.topAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.topAnchor, constant: offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else {
            c = self.topAnchor.constraint(equalTo: self.superview!.topAnchor, constant: offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToSuperviewBottom(offset: CGFloat = 0, activate: Bool = true, useSafeArea: Bool = false) -> NSLayoutConstraint {
        // NB: offset is negated to be more intuitive
        self.autoResizeTranslationCheck()
        let c: NSLayoutConstraint
        if useSafeArea {
            #if os(iOS)
            c = self.bottomAnchor.constraint(equalTo: self.superview!.safeAreaLayoutGuide.bottomAnchor, constant: -offset)
            #else
            c = NSLayoutConstraint(); assertionFailure("safeAreaLayoutGuide not supported on macOS")
            #endif
        } else {
            c = self.bottomAnchor.constraint(equalTo: self.superview!.bottomAnchor, constant: -offset)
        }
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToSuperviewXCenter(offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = self.centerXAnchor.constraint(equalTo: self.superview!.centerXAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToSuperviewYCenter(offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = self.centerYAnchor.constraint(equalTo: self.superview!.centerYAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToSuperviewYCenter(multiplier: CGFloat) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: self.superview, attribute: .centerY, multiplier: multiplier, constant: 0)
        c.isActive = true
        return c
    }
    @discardableResult public func constrainToXCenterOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = self.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToYCenterOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = self.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToTopOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.topAnchor.constraint(equalTo: self.bottomAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainTopToTopOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.topAnchor.constraint(equalTo: self.topAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainTopToBottomOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        // NB: offset is negated to be more intuitive
        self.autoResizeTranslationCheck()
        let c = view.bottomAnchor.constraint(equalTo: self.topAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainBottomToBottomOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainBottomToTopOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.topAnchor.constraint(equalTo: self.bottomAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToLeadingOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainLeadingToLeadingOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: -offset)
        if activate {
            c.isActive = activate
        }
        return c
    }
    @discardableResult public func constrainLeadingToTrailingOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.trailingAnchor.constraint(equalTo: self.leadingAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainLeftToRightOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.rightAnchor.constraint(equalTo: self.leftAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainTrailingToLeadingOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.leadingAnchor.constraint(equalTo: self.trailingAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainToTrailingOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.trailingAnchor.constraint(equalTo: self.leadingAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainTrailingToTrailingOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainWidthEqualTo(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.widthAnchor.constraint(equalTo: self.widthAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func constrainHeightEqualTo(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.heightAnchor.constraint(equalTo: self.heightAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func alignBottomToBottomOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: offset)
        c.isActive = activate
        return c
    }
    @discardableResult public func alignBottomToTopOf(_ view: View, offset: CGFloat = 0, activate: Bool = true) -> NSLayoutConstraint {
        self.autoResizeTranslationCheck()
        let c = view.topAnchor.constraint(equalTo: self.bottomAnchor, constant: offset)
        c.isActive = activate
        return c
    }
}

extension NSLayoutConstraint {
    // Use with care. But there are legit scenarios where layout warnings are benign, notably when there's a bunch of incoming constraints that might conflict serially but not as a batch.
    static public func setWarningsEnabled(_ enabled: Bool) {
        UserDefaults.standard.setValue(enabled, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }
}
