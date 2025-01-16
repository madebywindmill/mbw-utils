//
//  AppKitExtras.swift
//
//  Created by John Scalo on 2/3/21.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

#if os(OSX)

import AppKit

public extension NSWindow {
    /// Hides the effect background view in the toolbar behind the Inspector area, without any SPI!
    func inspectorToolbarBackgroundView() -> NSVisualEffectView? {
        guard let titlebarContainer = contentView?.superview?.subviews.first(where: { view in
            String(describing: view).contains("NSTitlebarContainerView")
        }) else { return nil }
        guard let titlebarView = titlebarContainer.subviews.first(where: { view in
            String(describing: view).contains("NSTitlebarView")
        }) else { return nil }
        let effectViews = titlebarView.subviews.compactMap({ view in
            view is NSVisualEffectView ? view : nil
        })
        
        for effectView in effectViews {
            if effectView.frame.origin.x > 0 {
                return effectView as? NSVisualEffectView
            }
        }
        return nil
    }
}

public extension NSView {
    /// Sets `newClipsToBounds` on all `subviews`, including _their_ subviews.
    func setClipsToBoundsForAllSubviews(_ newClipsToBounds: Bool) {
        for view in subviews {
            view.clipsToBounds = newClipsToBounds
            view.setClipsToBoundsForAllSubviews(newClipsToBounds)
        }
    }
    
    func bringSubviewToFront(_ view: NSView) {
        let context = Unmanaged.passUnretained(view).toOpaque()
        
        self.sortSubviews({ (viewA, viewB, context) -> ComparisonResult in
            let theView = Unmanaged<NSView>.fromOpaque(context!).takeUnretainedValue()
            
            if viewA == theView {
                return .orderedDescending
            } else if viewB == theView {
                return .orderedAscending
            } else {
                return .orderedSame
            }
        }, context: context)
    }

    var isFirstResponder: Bool {
        return self.window?.firstResponder == self
    }

    var viewBackgroundColor: NSColor? {
        get {
            if let cgcolor = layer?.backgroundColor {
                return NSColor(cgColor: cgcolor)
            } else {
                return nil
            }
        }
        set {
            self.wantsLayer = true
            self.layer?.backgroundColor = newValue?.cgColor
        }
    }
}

public extension NSTextView {
    func rectFor(range: NSRange) -> NSRect? {
        if usesTextKit2() {
            return nil
        } else {
            guard let layoutManager = layoutManager, let textContainer = textContainer else {
                return nil
            }
            
            let range = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            var rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
            rect = rect.offsetBy(dx: textContainerOrigin.x, dy: textContainerOrigin.y)
            return rect
        }
    }
    
    var rectForActiveRange: NSRect {
        if usesTextKit2() {
            return .zero
        } else {
            guard let layoutManager = layoutManager, let textContainer = textContainer else {
                return NSRect()
            }
            
            let range = layoutManager.glyphRange(forCharacterRange: selectedRange(), actualCharacterRange: nil)
            var rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
            rect = rect.offsetBy(dx: textContainerOrigin.x, dy: textContainerOrigin.y)
            return rect
        }
    }
    
    /// Returns the range of the current word based on where the text cursor is.
    var rangeForCurrentWord: NSRange? {
        let string = NSMutableString(string: string)
        if selectedRange().length > 0 {
            return selectedRange()
        } else {
            let insertionPoint = selectedRange().location
            
            // Look before and after for "new word" separators (aka, spaces and attachment characters).
            var startOfWordIndex: Int?
            var endOfWordIndex: Int?
            
            var searchIndex = insertionPoint
            let characterSetToLookFor = CharacterSet(charactersIn: " \r\n\(String.attachmentCharacter)")
            
            // Search forward for end of word if not at the end already
            if insertionPoint != string.length {
                while searchIndex < string.length {
                    let substring = string.substring(with: NSRange(location: searchIndex, length: 1)) as NSString
                    if substring.rangeOfCharacter(from: characterSetToLookFor).location != NSNotFound {
                        endOfWordIndex = searchIndex
                        break
                    }
                    searchIndex += 1
                }
            } else {
                endOfWordIndex = insertionPoint
            }

            // Search backward for start of word
            searchIndex = insertionPoint - 1
            while searchIndex >= 0 {
                let substring = string.substring(with: NSRange(location: searchIndex, length: 1)) as NSString
                if substring.rangeOfCharacter(from: characterSetToLookFor).location != NSNotFound {
                    startOfWordIndex = searchIndex + 1
                    break
                }
                if nil == startOfWordIndex && searchIndex == 0 {
                    startOfWordIndex = 0
                }
                searchIndex -= 1
            }
            
            if let startOfWordIndex, let endOfWordIndex, endOfWordIndex >= startOfWordIndex {
                return NSRange(location: startOfWordIndex, length: endOfWordIndex - startOfWordIndex)
            } else {
                return selectedRange()
            }
        }
    }
    
    var rectForCurrentWord: NSRect? {
        guard let rangeForCurrentWord else { return nil }
        return rectFor(range: rangeForCurrentWord)
    }
    
    func usesTextKit2() -> Bool {
        if #available(macOS 12, *) {
            return textLayoutManager != nil
        } else {
            return false
        }
    }
    
    func textHeight() -> CGFloat? {
        return intrinsicContentSize.height
    }
    
}

public extension NSTableView {
    func rowIsVisible(_ row: Int) -> Bool {
        let visibleRowsRange = rows(in: visibleRect)
        return visibleRowsRange.contains(row)
    }
    
    func visibleCells() -> [NSTableCellView] {
        var visibleCells: [NSTableCellView] = []
        let visibleRowRange = rows(in: self.visibleRect)
        for rowIndex in visibleRowRange.location..<visibleRowRange.upperBound {
            if let rowView = rowView(atRow: rowIndex, makeIfNecessary: false) {
                for subview in rowView.subviews {
                    if let cellView = subview as? NSTableCellView {
                        visibleCells.append(cellView)
                    }
                }
            }
        }
        return visibleCells
    }
}

public extension NSMenu {
    func item(withIdentifier identifier: String) -> NSMenuItem? {
        return items.first { item in
            item.identifier?.rawValue == identifier
        }
    }
}

public extension NSAlert {
    static func presentSimpleAlertOn(_ window: NSWindow?, title: String, message: String? = nil, completion: (()->Void)? = nil) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message ?? ""
        alert.addButton(withTitle: "OK")
        if let window {
            alert.beginSheetModal(for: window) { (response) in
                completion?()
            }
        } else {
            alert.runModal()
        }
    }
}

public extension NSColor {
    var hex3String: String {
        guard let colorSpace = self.cgColor.colorSpace else {
            assertionFailure("couldn't get colorSpace")
            return "000000"
        }
        guard let components = self.cgColor.components else {
            assertionFailure("couldn't get color components")
            return "000000"
        }
        
        switch colorSpace.model {
            case .rgb:
                guard components.count >= 3 else {
                    assertionFailure("unexpected number of color components")
                    return "000000"
                }
                let r: CGFloat = components[0]
                let g: CGFloat = components[1]
                let b: CGFloat = components[2]
                return String(
                    format: "%02lX%02lX%02lX",
                    lroundf(Float(r * 255)),
                    lroundf(Float(g * 255)),
                    lroundf(Float(b * 255))
                )
                
            case .monochrome:
                guard components.count >= 1 else {
                    assertionFailure("unexpected number of color components")
                    return "000000"
                }
                let white: CGFloat = components[0]
                return String(
                    format: "%02lX%02lX%02lX",
                    lroundf(Float(white * 255)),
                    lroundf(Float(white * 255)),
                    lroundf(Float(white * 255))
                )
                
            default:
                assertionFailure("unknown colorspace: \(colorSpace.model)")
                return "000000"
        }
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
        guard let components = self.cgColor.components else {
            assertionFailure("couldn't get color components")
            return "000000"
        }
        
        guard components.count >= 4 else {
            assertionFailure("unexpected number of color components")
            return "000000"
        }

        let r: CGFloat = components[0]
        let g: CGFloat = components[1]
        let b: CGFloat = components[2]
        let a: CGFloat = components[3]
        
        return String.init(
            format: "%02lX%02lX%02lX%02lX",
            lroundf(Float(r * 255)),
            lroundf(Float(g * 255)),
            lroundf(Float(b * 255)),
            lroundf(Float(a * 255))
        )
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
}

public extension NSImage {
    
    @available(iOS 13, macOS 12.0, watchOS 6, *)
    class func downloadImageToFile(from url: URL, authorizationHeader: [String:String]? = nil) async throws -> URL {
        let imageData = try await Data.from(url: url, authorizationHeader: authorizationHeader)
        
        if let cacheDirectory = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) as URL? {
            let filename = NSUUID().uuidString + imageData.imageFileExtension
            let saveToURL = cacheDirectory.appendingPathComponent(filename)
            try imageData.write(to: saveToURL)
            return saveToURL
        } else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError)
        }
    }
    
    class func removeCachedImageFrom(url: URL) {
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 10.0)
        URLCache.shared.removeCachedResponse(for: request)
    }
    
    class func cachedImageFrom(url: URL, authorizationHeader: [String:String]? = nil) -> NSImage? {
        if let data = Data.cachedDataFrom(url: url, authorizationHeader: authorizationHeader), let image = NSImage(data: data) {
            return image
        } else {
            return nil
        }
    }
    
    @available(iOS 13, macOS 12.0, watchOS 6, *)
    class func image(from url: URL, authorizationHeader: [String:String]? = nil, cachePolicy: NSURLRequest.CachePolicy) async throws -> NSImage? {
        if let cachedImage = cachedImageFrom(url: url, authorizationHeader: authorizationHeader) {
            return cachedImage
        } else {
            let imageData = try await Data.from(url: url, returnCachedDataIfAvailable: false, authorizationHeader: authorizationHeader, cachePolicy: cachePolicy)
            guard let image = NSImage(data: imageData) else {
                throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create image from data"])
            }
            return image
        }
    }

    var sizeInBytes: Int {
        guard let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            assertionFailure()
            return 0
        }
        return cgImage.bytesPerRow * cgImage.height
    }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        let cgImage = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        return bitmapRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: [.compressionFactor:compressionQuality])
    }
    
    func pngData() -> Data? {
        guard let tiffRepresentation = self.tiffRepresentation else {
            return nil
        }

        guard let bitmapImageRep = NSBitmapImageRep(data: tiffRepresentation) else {
            return nil
        }

        return bitmapImageRep.representation(using: .png, properties: [:])
    }

    // Returns optional to conform with UIImage.resize(targetSizePx:)
    func resize(targetSizePx: CGSize) -> NSImage? {
        let size = self.size
        
        let widthRatio  = targetSizePx.width  / self.size.width
        let heightRatio = targetSizePx.height / self.size.height
        var newSize: CGSize
        
        if widthRatio > heightRatio {
            newSize = CGSize(width: floor(size.width * heightRatio), height: floor(size.height * heightRatio))
        } else {
            newSize = CGSize(width: floor(size.width * widthRatio),  height: floor(size.height * widthRatio))
        }
        
        return self.resize(newSize)
    }
    
    // Returns optional to conform with UIImage.resize()
    func resize(_ newSize: NSSize) -> NSImage? {
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height),
                  from: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height),
                  operation: .sourceOver,
                  fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}

public extension NSFont {
    static func systemItalicFont(ofSize fontSize: CGFloat) -> NSFont {
        let systemFont = NSFont.systemFont(ofSize: fontSize, weight: .regular)
        let descriptor = systemFont.fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: fontSize) ?? systemFont
    }

    static func systemBoldFont(ofSize fontSize: CGFloat, weight: NSFont.Weight) -> NSFont {
        let systemFont = NSFont.systemFont(ofSize: fontSize, weight: weight)
        let descriptor = systemFont.fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: fontSize) ?? systemFont
    }

    func mergedWithTraitsFrom(_ otherFont: NSFont) -> NSFont? {
        let traits1 = self.fontDescriptor.symbolicTraits
        let traits2 = otherFont.fontDescriptor.symbolicTraits

        // Merge the traits
        let mergedTraits = traits1.union(traits2)

        // Get the base font's descriptor and apply the merged traits
        let mergedDescriptor = self.fontDescriptor.withSymbolicTraits(mergedTraits)

        // Return a new font with the merged descriptor and the size of the first font
        return NSFont(descriptor: mergedDescriptor, size: self.pointSize)
    }
    
    func mergeTrait(_ trait: NSFontDescriptor.SymbolicTraits) -> NSFont? {
        let mergedTraits = self.fontDescriptor.symbolicTraits.union(trait)
        let mergedDescriptor = self.fontDescriptor.withSymbolicTraits(mergedTraits)
        return NSFont(descriptor: mergedDescriptor, size: self.pointSize)
    }
    
    var hasBold: Bool {
        return self.fontDescriptor.symbolicTraits.contains(.bold)
    }
    var hasItalic: Bool {
        return self.fontDescriptor.symbolicTraits.contains(.italic)
    }
}


#endif
