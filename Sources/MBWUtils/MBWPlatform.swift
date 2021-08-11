//
//  MBWPlatform.swift
//  
//
//  Created by John Scalo on 2/4/21.
//

#if os(iOS)
import UIKit
public typealias Font = UIFont
public typealias Image = UIImage
public typealias Color = UIColor
public typealias FontDescriptor = UIFontDescriptor
#else // osx
import AppKit
public typealias Font = NSFont
public typealias Image = NSImage
public typealias Color = NSColor
public typealias FontDescriptor = NSFontDescriptor
#endif

// On macOS Font.familyName is an optional but on iOS it's not. Conform to iOS.
public extension Font {
    var platformFriendlyFamilyName: String {
        #if os(iOS)
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
