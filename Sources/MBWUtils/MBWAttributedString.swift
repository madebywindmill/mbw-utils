//
//  MBWAttributedString.swift
//
//  Created by John Scalo on 3/21/17.
//  Copyright © 2017-2021 Made by Windmill. All rights reserved.
//
// Example usage:
// let attrStr = MBWAttributedString()
// someLabel.attributedText = attrStr.bold("some bold text") + attrStr.norm(" some normal text")
//

#if os(iOS)
import UIKit
#elseif os(OSX)
import AppKit
#elseif os(watchOS)
import WatchKit
#endif

public class MBWAttributedString {
    
    public init() {}

    public var normAttrs: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : Font.systemFont(ofSize: 15.0, weight: .regular)]
    public var boldAttrs: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : Font.systemFont(ofSize: 15.0, weight: .bold)]
    public var lightAttrs: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : Font.systemFont(ofSize: 15.0, weight: .light)]
    public var other1Attrs: [NSAttributedString.Key : Any] = [:]
    public var other2Attrs: [NSAttributedString.Key : Any] = [:]
    public var other3Attrs: [NSAttributedString.Key : Any] = [:]

    public var attributedString = NSMutableAttributedString()
    
    public func norm(_ str: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: str, attributes: self.normAttrs)
    }
    public func bold(_ str: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: str, attributes: self.boldAttrs)
    }
    public func light(_ str: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: str, attributes: self.lightAttrs)
    }
    public func other1(_ str: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: str, attributes: self.other1Attrs)
    }
    public func other2(_ str: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: str, attributes: self.other2Attrs)
    }
    public func other3(_ str: String) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: str, attributes: self.other3Attrs)
    }
}

public extension String {
    
    var attributed: NSAttributedString {
        return NSAttributedString(string: self)
    }
    
    var light: NSAttributedString {
        return NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : Font.systemFont(ofSize: 17.0, weight: .light)])
    }
    
    var regular: NSAttributedString {
        return NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : Font.systemFont(ofSize: 17.0, weight: .regular)])
    }
    
    var semibold: NSAttributedString {
        return NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : Font.systemFont(ofSize: 17.0, weight: .semibold)])
    }
    
    var bold: NSAttributedString {
        return NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : Font.systemFont(ofSize: 17.0, weight: .bold)])
    }
}

public extension NSAttributedString {
    
    static func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        let newstr = NSMutableAttributedString(attributedString: lhs)
        newstr.append(rhs)
        return newstr
    }
    
    func strikethrough() -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.addAttribute(.strikethroughStyle, value: 1, range: NSRange(location: 0, length: mutableString.length))
        return mutableString
    }
    
    func letterpressed() -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        #if !targetEnvironment(simulator) && !targetEnvironment(macCatalyst)
        mutableString.addAttribute(.textEffect, value: NSAttributedString.TextEffectStyle.letterpressStyle, range: NSRange(location: 0, length: mutableString.length))
        #endif
        return mutableString
    }
    
    func kern(_ points: Float) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.addAttribute(.kern, value: points, range: NSRange(location: 0, length: mutableString.length))
        return mutableString
    }
    
    func paragraphStyle(_ style: NSParagraphStyle) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: mutableString.length))
        return mutableString
    }
    
    func font(_ font: Font, color: Color? = nil) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.addAttribute(.font, value: font, range: NSRange(location: 0, length: mutableString.length))
        if let color = color {
            mutableString.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutableString.length))
        }
        return mutableString
    }
        
    func fontFace(_ font: Font, color: Color? = nil) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.setFontFace(font: font, color: color)
        return mutableString
    }
    
}

public extension NSMutableAttributedString {
    
    func setFontFace(font: Font, color: Color? = nil) {
        // TODO: fix Apple bug where SF rounded isn't getting the correct weight
        beginEditing()
        self.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: self.length)
        ) { (value, range, stop) in

            if let f = value as? Font,
              var newFontDescriptor = f.fontDescriptor
                .withFamily(font.platformFriendlyFamilyName)
                .platformFriendlyWithSymbolicTraits(f.fontDescriptor.symbolicTraits)
            {
                if let featureSettings = font.fontDescriptor.fontAttributes[.featureSettings] as? [Any] {
                    newFontDescriptor = newFontDescriptor.addingAttributes([FontDescriptor.AttributeName.featureSettings: featureSettings])
                }
                if let traits = font.fontDescriptor.fontAttributes[.traits] {
                    newFontDescriptor = newFontDescriptor.addingAttributes([FontDescriptor.AttributeName.traits: traits])
                }
                
                
                let newFont = Font(
                    descriptor: newFontDescriptor,
                    size: font.pointSize
                )
                removeAttribute(.font, range: range)
#if os(iOS) || os(watchOS)
                addAttribute(.font, value: newFont, range: range)
#elseif os(OSX)
                if let newFont = newFont {
                    addAttribute(.font, value: newFont, range: range)
                }
#endif
                if let color = color {
                    removeAttribute(
                        .foregroundColor,
                        range: range
                    )
                    addAttribute(
                        .foregroundColor,
                        value: color,
                        range: range
                    )
                }
            }
        }
        endEditing()
    }
}
