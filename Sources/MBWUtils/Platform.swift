//
//  Platform.swift
//  
//
//  Created by John Scalo on 2/4/21.
//

#if os(iOS)  || os(watchOS)
import UIKit
public typealias CocoaFont = UIFont
public typealias CocoaImage = UIImage
public typealias CocoaColor = UIColor
public typealias FontDescriptor = UIFontDescriptor
#elseif os(OSX)
import AppKit
public typealias CocoaFont = NSFont
public typealias CocoaImage = NSImage
public typealias CocoaColor = NSColor
public typealias FontDescriptor = NSFontDescriptor
#endif

// On macOS CocoaFont.familyName is an optional but on iOS it's not. Conform to iOS.
public extension CocoaFont {
    var platformFriendlyFamilyName: String {
        #if os(iOS) || os(watchOS)
        return self.familyName
        #else
        return self.familyName ?? "unknown font family"
        #endif
    }
}

// On macOS FontDescriptor.withSymbolicTraits is non-optional but on iOS it's optional. Conform to iOS.
public extension FontDescriptor {
    func platformFriendlyWithSymbolicTraits(_ symbolicTraits: FontDescriptor.SymbolicTraits) -> FontDescriptor? {
        return self.withSymbolicTraits(symbolicTraits)
    }
}

public class Platform {
    public static var majorOSVersion: Int {
        return ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    }
    
    public static var minorOSVersion: Int {
        return ProcessInfo.processInfo.operatingSystemVersion.minorVersion
    }
}
