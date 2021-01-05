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

import UIKit

public class MBWAttributedString {
    
    public init() {}

    public var normAttrs: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15.0, weight: .regular)]
    public var boldAttrs: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15.0, weight: .bold)]
    public var lightAttrs: [NSAttributedString.Key : Any] = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15.0, weight: .light)]

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

}

extension String {
    
    public var attributed: NSAttributedString {
        return NSAttributedString(string: self)
    }
    
    public var light: NSAttributedString {
        return NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17.0, weight: .light)])
    }
    
    public var regular: NSAttributedString {
        return NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17.0, weight: .regular)])
    }
    
    public var semibold: NSAttributedString {
        return NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17.0, weight: .semibold)])
    }
    
    public var bold: NSAttributedString {
        return NSAttributedString(string: self, attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 17.0, weight: .bold)])
    }
}

extension NSAttributedString {
    
    public static func +(lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString {
        let newstr = NSMutableAttributedString(attributedString: lhs)
        newstr.append(rhs)
        return newstr
    }
    
    public func strikethrough() -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.addAttribute(.strikethroughStyle, value: 1, range: NSRange(location: 0, length: mutableString.length))
        return mutableString
    }
    
    public func letterpressed() -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        #if !targetEnvironment(simulator) && !targetEnvironment(macCatalyst)
        mutableString.addAttribute(.textEffect, value: NSAttributedString.TextEffectStyle.letterpressStyle, range: NSRange(location: 0, length: mutableString.length))
        #endif
        return mutableString
    }
    
    public func kern(_ points: Float) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.addAttribute(.kern, value: points, range: NSRange(location: 0, length: mutableString.length))
        return mutableString
    }
    
    public func paragraphStyle(_ style: NSParagraphStyle) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.addAttribute(.paragraphStyle, value: style, range: NSRange(location: 0, length: mutableString.length))
        return mutableString
    }
    
    public func font(_ font: UIFont, color: UIColor? = nil) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.addAttribute(.font, value: font, range: NSRange(location: 0, length: mutableString.length))
        if let color = color {
            mutableString.addAttribute(.foregroundColor, value: color, range: NSRange(location: 0, length: mutableString.length))
        }
        return mutableString
    }
    
    public func fontFace(_ font: UIFont, color: UIColor? = nil) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: self)
        mutableString.setFontFace(font: font, color: color)
        return mutableString
    }
    
}

extension NSMutableAttributedString {
    
    public func setFontFace(font: UIFont, color: UIColor? = nil) {
        // TODO: fix Apple bug where SF rounded isn't getting the correct weight
        beginEditing()
        self.enumerateAttribute(
            .font,
            in: NSRange(location: 0, length: self.length)
        ) { (value, range, stop) in

            if let f = value as? UIFont,
              var newFontDescriptor = f.fontDescriptor
                .withFamily(font.familyName)
                .withSymbolicTraits(f.fontDescriptor.symbolicTraits)
            {
                if let featureSettings = font.fontDescriptor.fontAttributes[.featureSettings] as? [Any] {
                    newFontDescriptor = newFontDescriptor.addingAttributes([UIFontDescriptor.AttributeName.featureSettings: featureSettings])
                }
                if let traits = font.fontDescriptor.fontAttributes[.traits] {
                    newFontDescriptor = newFontDescriptor.addingAttributes([UIFontDescriptor.AttributeName.traits: traits])
                }


                let newFont = UIFont(
                    descriptor: newFontDescriptor,
                    size: font.pointSize
                )
                removeAttribute(.font, range: range)
                addAttribute(.font, value: newFont, range: range)
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
