//
//  StringExtras.swift
//  MBWUtils
//
//  Created by John Scalo on 1/16/25.
//

import Foundation
#if os(iOS)  || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

public typealias StringAttrs = [NSAttributedString.Key: Any]

public let unicharLF = 10
public let unicharCR = 13
public let unicharSpace = 32
public let unicharBackslash = 92
public let unicharBacktick = 96
public let unicharTab = 9

public let punctuationCharSet = CharacterSet.punctuationCharacters
public let whitespaceCharSet = CharacterSet.whitespaces
public let newlinesCharSet = CharacterSet.newlines
public let nonNewlinesCharSet = CharacterSet.newlines.inverted
public let whitespaceAndNewlinesCharSet = CharacterSet.whitespacesAndNewlines
public let nonWhitespaceCharSet = CharacterSet.whitespaces.inverted
public let nonWhitespaceAndNewlinesCharSet = nonNewlinesCharSet.union(nonWhitespaceCharSet)
public let nonCharacterSet = whitespaceAndNewlinesCharSet.union(.controlCharacters)
// pretty much anything that's not whitespace, control characters, or punctuaton
public let regularCharacterSet = nonCharacterSet.union(.punctuationCharacters).inverted

// precompile regex for speed
public let hyperlinkRegex = try! NSRegularExpression(
    pattern: "(https?://(?:www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z]{2,6}\\b(?:/[-a-zA-Z0-9@:%_\\+.~#?&//=]*)?)",
    options: []
)

public extension String {
    static var attachmentCharacter: String {
        return "\u{fffc}"
    }

    static func fromUnichar(_ c: unichar) -> String {
        if let char = Character.fromUnichar(c) {
            return String(char)
        } else {
            return ""
        }
    }

    /// Can be used for shorter UUIDs.
    static func random(length: Int) -> String {
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

        return String((0..<length).compactMap { _ in
            chars.randomElement()
        })
    }

    var nsString: NSString {
        return self as NSString
    }
    
    /// NOT the same as count. Use with care.
    var length: Int {
        return utf16.count
    }

    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: self)
    }
    
    var isAllNumbers: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
    
    var removingAttachmentCharacters: String {
        return replacingOccurrences(of: String.attachmentCharacter, with: "")
    }

    var trimmingWhitespace: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    func substring(_ range: Range<Int>) -> String {
        guard range.lowerBound >= 0 else {
            print("lowerBound is negative."); return ""
        }
        guard range.lowerBound < self.count else {
            print("lowerBound is out of range."); return ""
        }
        guard range.upperBound <= self.count else {
            print("upperBound is out of range."); return ""
        }
        guard range.upperBound > 0 else {
            print("upperBound is out of range."); return ""
        }
        guard range.lowerBound != range.upperBound else {
            print("lowerBound is the same as upperBound."); return ""
        }
        
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
        
        return String(self[startIndex ..< endIndex])
    }

    func substring(_ range: ClosedRange<Int>) -> String {
        guard range.lowerBound >= 0 else {
            print("lowerBound is negative."); return ""
        }
        guard range.lowerBound < self.count else {
            print("lowerBound is out of range."); return ""
        }
        guard range.upperBound < self.count else {
            print("upperBound is out of range."); return ""
        }

        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: range.upperBound + 1)

        return String(self[startIndex..<endIndex])
    }
    
    func substring(_ range: PartialRangeFrom<Int>) -> String {
        guard range.lowerBound >= 0 else {
            print("lowerBound is negative."); return ""
        }
        guard range.lowerBound < self.count else {
            print("lowerBound is out of range."); return ""
        }
        
        let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
        let endIndex = self.index(self.startIndex, offsetBy: self.count)
        
        return String(self[startIndex ..< endIndex])
    }

    /// Warning: this parameter naming here isn't great. The `to` is "up to AND including". E.g. the 2nd character would be `str.substring(from: 1, to: 1)`.
    @available(*, deprecated, message: "Use substring(_ range:) instead.")
    func substring(from: Int?, to: Int?) -> String {
        if let start = from {
            guard start < self.count else {
                return ""
            }
        }
        
        if let end = to {
            guard end >= 0 else {
                return ""
            }
        }
        
        if let start = from, let end = to {
            guard end - start >= 0 else {
                return ""
            }
        }
        
        let startIndex: String.Index
        if let start = from, start >= 0 {
            startIndex = self.index(self.startIndex, offsetBy: start)
        } else {
            startIndex = self.startIndex
        }
        
        let endIndex: String.Index
        if let end = to, end >= 0, end < self.count {
            endIndex = self.index(self.startIndex, offsetBy: end + 1)
        } else {
            endIndex = self.endIndex
        }
        
        return String(self[startIndex ..< endIndex])
    }
    
    @available(*, deprecated, message: "Use substring(_ range:) instead.")
    func substring(from: Int) -> String {
        return self.substring(from: from, to: nil)
    }
    
    /// Warning: this parameter naming here isn't great. The `to` is "up to AND including". E.g. the 1st character would be `str.substring(to: 0)`.
    @available(*, deprecated, message: "Use substring(_ range:) instead.")
    func substring(to: Int) -> String {
        return self.substring(from: nil, to: to)
    }
        
    @available(*, deprecated, message: "Use substring(_ range:) instead.")
    func substring(from: Int?, length: Int) -> String {
        guard length > 0 else {
            return ""
        }
        
        let end: Int
        if let start = from, start > 0 {
            end = start + length - 1
        } else {
            end = length - 1
        }
        
        return self.substring(from: from, to: end)
    }
    
    @available(*, deprecated, message: "Use substring(_ range:) instead.")
    func substring(length: Int, to: Int?) -> String {
        guard let end = to, end > 0, length > 0 else {
            return ""
        }
        
        let start: Int
        if let end = to, end - length > 0 {
            start = end - length + 1
        } else {
            start = 0
        }
        
        return self.substring(from: start, to: to)
    }
    
    func firstNCharacters(_ n: Int) -> String {
        return substring(0..<n)
    }
    
    func lastNCharacters(_ n: Int) -> String {
        return substring((self.count - n)...)
    }

    func index(offset: Int) -> String.Index {
        return self.index(self.startIndex, offsetBy: offset)
    }
    
    func replacingCharacters(from characterSet: CharacterSet, with string: String) -> String {
        return self.components(separatedBy: characterSet).joined(separator: string)
    }

    func removeSpaces() -> String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    
    func base64Encoded() -> String? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        return data.base64EncodedString()
    }
    
    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    func integerRanges(of substring: String) -> [(start: Int, end: Int)] {
        // Find all ranges of the substring
        let ranges = self.ranges(of: substring)
        
        // Convert ranges to integer offsets
        return ranges.map { (start: self.distance(from: self.startIndex, to: $0.lowerBound),
                             end: self.distance(from: self.startIndex, to: $0.upperBound) - 1) }
    }
    
    func ranges(of substring: String) -> [Range<String.Index>] {
        var ranges: [Range<String.Index>] = []
        var start = self.startIndex
        while let range = self.range(of: substring, range: start..<self.endIndex) {
            ranges.append(range)
            start = range.upperBound
        }
        return ranges
    }
    
    func removingFirstCharacter() -> String {
        guard !isEmpty else { return self }
        return String(self[index(after: startIndex)...])
    }
    
    func truncated(to length: Int) -> String {
        return (self.count > length) ? self.prefix(length) + "…" : self
    }

    /// Returns the location of the next newline (\n) character starting at (and including) the given location.
    /// **Not safe for \r\n**!!
    func locationOfInclusiveNextNewline(from location: Int) -> Int? {
        return (self as NSString).locationOfInclusiveNextNewline(from: location)
    }

    func locationOfEndOfLine(from location: Int) -> Int {
        return (self as NSString).locationOfEndOfLine(from: location)
    }
    
    func replacingUnprintableCharacters() -> String {
        var escapedString = ""
        for char in self {
            switch char {
                case "\n": escapedString += "\\n"
                case "\t": escapedString += "\\t"
                case "\r": escapedString += "\\r"
                case "\r\n": escapedString += "\\r\\n"
                default: escapedString += String(char)
            }
        }
        return escapedString
    }

    func convertingNewlines() -> String {
        return self
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
        
    func firstNonWhitespaceChar() -> String? {
        for character in self {
            if !character.isWhitespace {
                return String(character)
            }
        }
        return nil
    }
    
    /// Returns the string starting at location and going to the next newline, or the rest of the string if there is no newline
    /// If location points to a newline, it is skipped before searching.
    func remainingPartOfLine(from location: Int) -> String? {
        guard location >= 0, location < self.count else { return nil }

        let startIndex = self.index(self.startIndex, offsetBy: location)
        var currentIndex = startIndex

        if self[currentIndex] == "\n", currentIndex < self.endIndex {
            currentIndex = self.index(after: currentIndex)
        }

        if let newLineIndex = self[currentIndex...].firstIndex(of: "\n") {
            return String(self[currentIndex..<newLineIndex])
        } else {
            return String(self[currentIndex...])
        }
    }
    
    func hyperlinkRanges() -> [NSRange] {
        return self.nsString.hyperlinkRanges()
    }
        
    func removingFromStart(_ str: String) -> String {
        var newStr = self
        if let range = self.range(of: str), range.lowerBound == self.startIndex {
            newStr.removeSubrange(range)
        }
        return newStr
    }
}

public extension NSString {
    var string: String {
        return (self as String)
    }
    
    var isNewline: Bool {
        return self == "\n" || self == "\r\n" || self == "\r"
    }
        
    var newlineEnding: NSString? {
        if self.hasSuffix("\n") {
            if self.length > 1 && self.character(at: self.length - 2) == unichar("\r".unicodeScalars.first!.value) {
                return "\r\n"
            } else {
                return "\n"
            }
        }
        return nil
    }

    var wholeRange: NSRange {
        return NSRange(0, length)
    }

    func allRanges(of substring: String) -> [NSRange] {
        var ranges = [NSRange]()
        var range = NSRange(location: 0, length: self.length)
        
        var foundRange = NSRange()
        repeat {
            foundRange = self.range(of: substring, options: [], range: range)
            if foundRange.location != NSNotFound {
                ranges.append(foundRange)
                range = NSRange(location: foundRange.location + foundRange.length, length: self.length - foundRange.location - foundRange.length)
            }
        } while foundRange.location != NSNotFound
        
        return ranges
    }
    
    func hasNewlineAt(_ location: Int) -> Bool {
        if location >= length {
            return false
        }
        let c = character(at: location)
        if c == unicharCR {
            // check for next \n
            if length > location + 1 {
                let c2 = character(at: location + 1)
                if c2 == unicharLF {
                    return true
                } else {
                    assertionFailure() // CR by itself never expected
                    return true
                }
            } else {
                return true
            }
        } else if c == unicharLF {
            return true
        } else {
            return false
        }
    }

    func hasNewlineAt(_ location: Int, newlineStr: inout NSString) -> Bool {
        if location >= length {
            newlineStr = ""
            return false
        }
        let c = character(at: location)
        if c == unicharCR {
            // check for next \n
            if length > location + 1 {
                let c2 = character(at: location + 1)
                if c2 == unicharLF {
                    newlineStr = "\r\n"
                    return true
                } else {
                    assertionFailure() // CR by itself never expected
                    newlineStr = "\r"
                    return true
                }
            } else {
                newlineStr = "\r"
                return true
            }
        } else if c == unicharLF /* \n */ {
            newlineStr = "\n"
            return true
        } else {
            newlineStr = ""
            return false
        }
    }
        
    /// Returns the location of the next newline (\n) character starting at (and including) the given location.
    /// **Not safe for \r\n**!!
    func locationOfInclusiveNextNewline(from location: Int) -> Int? {
        var idx = location
        while idx < length {
            let c = self.character(at: idx)
            if c == unicharLF {
                return idx
            }
            idx += 1
        }
        return nil
    }
    
    func locationOfEndOfLine(from location: Int) -> Int {
        var lineStart = 0
        var lineEnd = 0
        var contentsEnd = 0
        
        getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: location, length: 0))
        
        return lineEnd
    }
    
    func remainingPartOfLine(from location: Int) -> NSString? {
        return string.remainingPartOfLine(from: location)?.nsString
    }

    /// Same as above but doesn't skip newline at location.
    /// TODO: merge these
    func remainingPartOfLineNew(from location: Int) -> NSString? {
        let newlineCharSet = CharacterSet.newlines
        let searchRange = NSRange(location: location, length: self.length - location)
        let newlineRange = self.rangeOfCharacter(from: newlineCharSet, options: [], range: searchRange)

        if newlineRange.location != NSNotFound {
            // add 1 to length to include newline
            return self.substring(with: NSRange(location: location, length: newlineRange.location - location + 1)) as NSString
        } else {
            return self.substring(from: location) as NSString
        }
    }
    
    func hasPrefix(_ otherStr: NSString) -> Bool {
        return hasPrefix(otherStr.string)
    }
    
    // Returns the range of the line of text surrounding the given location, not including any trailing newline character.
    // Not CRLF safe!
    func rangeOfSurroundingLine(at location: Int) -> NSRange {
        guard length > 0, location >= 0, location < length else {
            return NSRange(NSNotFound, 0)
        }

        let range = NSRange(location: location, length: 0)
        let lineRange = lineRange(for: range)

        // exclude newline if necessary
        var adjustedLineRange = lineRange
        if adjustedLineRange.length > 0,
           character(at: adjustedLineRange.upperBound - 1) == unicharLF
        {
            adjustedLineRange.length -= 1
        }

        return adjustedLineRange
    }
    
    // Returns the line of text surrounding the given location, not including any trailing newline character.
    // Not CRLF safe!
    func surroundingLine(at location: Int) -> NSString {
        let range = rangeOfSurroundingLine(at: location)
        if range.location == NSNotFound {
            return ""
        } else {
            return substring(with: range) as NSString
        }
    }
    
    /// hyperlinkRanges() is slow (thanks regex!) and can be called often so we do all we can to optimize.
    /// * precompile the regex statically (huge time saver actually)
    /// * cache the results - calls to hyperlinkRanges tend to be very local so the cache can be small, 10K currently
    static var hyperlinkRangesCache: NSCache<NSString, NSArray>!
    
    /// Clients should call `NSString.setUpCaches()` if they intend to use `hyperlinkRanges()`
    static func setUpCaches() {
        hyperlinkRangesCache = NSCache()
        hyperlinkRangesCache.totalCostLimit = 10 * 1024 // 10K
    }
    func cachedHyperlinkRanges() -> [NSRange]? {
        guard Self.hyperlinkRangesCache != nil else {
            return nil
        }
        if let a = Self.hyperlinkRangesCache.object(forKey: self) {
            return a as? [NSRange]
        } else {
            return nil
        }
    }
    static func cacheHyperlinkRanges(_ a: [NSRange], str: NSString) {
        guard Self.hyperlinkRangesCache != nil else {
            Logger.log("*** warning: trying to cache hyperlink range without first creating the cache object")
            return
        }
        hyperlinkRangesCache.setObject(a as NSArray, forKey: str)
    }
    
    func hyperlinkRanges() -> [NSRange] {
        if let cachedA = cachedHyperlinkRanges() {
            return cachedA
        }
        let matches = hyperlinkRegex.matches(in: self as String, options: [], range: NSRange(location: 0, length: self.length))
        var ranges: [NSRange] = []
        for match in matches {
            let range = match.range
            // exclue hyperlinks that are part of a markdown link
            if range.location >= 2 && self.substring(with: NSRange(location: range.location - 2, length: 2)) == "](" {
                continue
            }
            ranges.append(range)
        }
        if Self.hyperlinkRangesCache != nil {
            Self.cacheHyperlinkRanges(ranges, str: self)
        }
        return ranges
    }
}

public extension NSMutableAttributedString {
    
#if os(iOS) || os(macOS)
    /// Apply the given font across the range of the receiver. If a font already exists anywhere within the range, and the font has a trait of the given type, try to merge the trait with the given font. Otherwise replace any existing font with the given font.
    func mergeFont(_ font: CocoaFont,
                   range: NSRange,
                   with otherTrait: FontDescriptor.SymbolicTraits)
    {
        enumerateAttribute(.font, in: range, options: [.reverse]) { foundFont, foundRange, stop in
            if let foundFont = foundFont as? CocoaFont {
                if foundFont.fontDescriptor.symbolicTraits.contains(otherTrait) {
                    if let newFont = font.mergeTrait(otherTrait) {
                        removeAttribute(.font, range: foundRange)
                        addAttribute(.font, value: newFont, range: foundRange)
                    } else {
                        removeAttribute(.font, range: foundRange)
                        addAttribute(.font, value: font, range: foundRange)
                    }
                } else {
                    removeAttribute(.font, range: foundRange)
                    addAttribute(.font, value: font, range: foundRange)
                }
            } else {
                removeAttribute(.font, range: foundRange)
                addAttribute(.font, value: font, range: foundRange)
            }
        }
    }
#endif
    
    /// Applies all the attributes from otherAttrStr to this attr string across the given range.
    func applyAttrsFrom(_ otherAttrStr: NSAttributedString, range: NSRange) {
        otherAttrStr.enumerateAttributes(in: otherAttrStr.wholeRange) { d, foundRange, stop in
            let actualRange = NSRange(range.location + foundRange.location, foundRange.length)
            for (key,val) in d {
                addAttribute(key, value: val, range: actualRange)
            }
        }
    }
    
    func removeAllAttributes(range: NSRange) {
        enumerateAttributes(in: range) { d, foundRange, stop in
            for (key,_) in d {
                self.removeAttribute(key, range: foundRange)
            }
        }
    }
    
    func replaceCharacters(in range: NSRange, string: String, attrs: StringAttrs) {
        self.replaceCharacters(in: range, with: string)
        self.setAttributes(attrs, range: NSRange(range.location, string.length))
    }

}

public extension NSMutableString {
    
    func appendChar(_ c: unichar) {
        let charString = NSString(characters: [c], length: 1)
        self.append(charString as String)
    }
    
    func trimWhitespace() {
        let trimmedString = self.trimmingCharacters(in: .whitespacesAndNewlines)
        self.setString(trimmedString)
    }
}

public extension NSAttributedString {
    
    var wholeRange: NSRange {
        return NSRange(location: 0, length: self.length)
    }
    
    var nsString: NSString {
        return self.string as NSString
    }
        
    // for debugging only
    func nextContinuousAttrString(from location: Int) -> NSAttributedString {
        var longestRange = NSRange(location: 0, length: 0)
        let _ = self.attributes(at: location, longestEffectiveRange: &longestRange, in: self.wholeRange)
        return self.attributedSubstring(from: longestRange)
    }
    
    // returns an array of tuples where .0 is the range and .1 is the attrs
    func allAttributeRuns() -> [(NSRange, StringAttrs)] {
        var runs: [(NSRange, [NSAttributedString.Key: Any])] = []
        
        self.enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { attributes, range, _ in
            runs.append((range, attributes))
        }
        
        return runs
    }

    func previousLineRange(from location: Int, includeNewline: Bool = false) -> NSRange? {
        if location == 0 {
            return nil
        }
        
        let nsString = self.string as NSString
        var lineStart = 0
        var lineEnd = 0
        var contentsEnd = 0
        
        var index = location - 1
        while index > 0 {
            nsString.getLineStart(&lineStart, end: &lineEnd, contentsEnd: &contentsEnd, for: NSRange(location: index, length: 0))
            
            if contentsEnd < lineEnd {
                if lineStart < contentsEnd {
                    let previousLineRange: NSRange
                    if includeNewline {
                        previousLineRange = NSRange(location: lineStart, length: lineEnd - lineStart)
                    } else {
                        previousLineRange = NSRange(location: lineStart, length: contentsEnd - lineStart)
                    }
                    return previousLineRange
                }
                break
            }
            
            index = lineStart - 1
        }
        
        return nil
    }
    
    func attributedStringOfPreviousLine(from location: Int, includeNewline: Bool = false) -> NSAttributedString? {
        
        if let range = previousLineRange(from: location, includeNewline: includeNewline) {
            return self.attributedSubstring(from: range)
        } else {
            return nil
        }
    }
    
    /// Returns an attributed substring containing the next line after location that begins after a newline.
    /// If location points to a newline, it is skipped before searching. If the line beginning at location has no trailing newline, nil is returned.
    /// **not \r\n safe!**
    func attributedStringOfNextLine(from location: Int) -> NSAttributedString? {
        var searchLoc = location
        
        if searchLoc >= length {
            return nil
        }

        let nsString = self.string as NSString

        // if the character _at_ location is a newline, then presumably the caller wants the _next_ line and not this one, so skip it.
        var skippedCurrentNewline = false
        if nsString.character(at: searchLoc) == unicharLF {
            skippedCurrentNewline = true
            searchLoc += 1
        }
        
        if searchLoc >= length {
            return nil
        }
        
        guard var nextNewlineLoc = nsString.locationOfInclusiveNextNewline(from: searchLoc) else {
            return nil
        }
        
        // handle the special case where there are two newlines in a row and just return the newline
        if skippedCurrentNewline && nextNewlineLoc == searchLoc {
            let range = NSRange(location: nextNewlineLoc, length: 1)
            return self.attributedSubstring(from: range)
        }
        
        // we have the location of the next newline character, but that's the _end_ of the current line, which we don't want so inc by 1.
        if !skippedCurrentNewline {
            nextNewlineLoc += 1
        }
        if nextNewlineLoc >= length {
            return nil
        }
                
        let range: NSRange
        if nextNewlineLoc + 1 >= nsString.length {
            range = NSRange(location: nextNewlineLoc, length: 1)
        } else if let nextNextNewlineLoc = nsString.locationOfInclusiveNextNewline(from: nextNewlineLoc + 1) {
            range = NSRange(location: nextNewlineLoc, length: nextNextNewlineLoc - nextNewlineLoc)
        } else {
            range = NSRange(location: nextNewlineLoc, length: nsString.length - nextNewlineLoc)
        }
        
        return self.attributedSubstring(from: range)
    }

    func hasAttribute(key: NSAttributedString.Key, value: AnyHashable, at location: Int) -> Bool {
        guard location < string.length else {
            return false
        }
        guard let val = attributes(at: location, effectiveRange: nil)[key] as? AnyHashable else {
            return false
        }
        return val == value
    }

    func hasAttribute(key: NSAttributedString.Key, at location: Int) -> Bool {
        guard location < string.length else {
            return false
        }
        if nil != attributes(at: location, effectiveRange: nil)[key] as? AnyHashable {
            return true
        } else {
            return false
        }
    }
            
    func hasNewlineAt(_ location: Int) -> Bool {
        return (self.string as NSString).hasNewlineAt(location)
    }

    func hasNewlineAt(_ location: Int, newlineStr: inout NSString) -> Bool {
        return (self.string as NSString).hasNewlineAt(location, newlineStr: &newlineStr)
    }
    
#if os(iOS) || os(macOS)
    func addingBackBoldAndItalicStylesFrom(_ otherAttrStr: NSAttributedString) -> NSAttributedString {
        guard self.length == otherAttrStr.length else {
            assertionFailure(); return self
        }
        
        let newAttrStr = NSMutableAttributedString(attributedString: self)
        
        otherAttrStr.enumerateAttribute(.font, in: wholeRange) { value, range, stop in
            guard let font = value as? CocoaFont else { return }
            if font.hasItalic || font.hasBold {
                newAttrStr.addAttribute(.font, value: font, range: range)
            }
        }
        
        return newAttrStr
    }
#endif

    func allAttributes() -> [String: [NSRange]] {
        var attributeDictionary: [String: [NSRange]] = [:]
        
        self.enumerateAttributes(in: NSRange(location: 0, length: self.length), options: []) { (attributes, range, _) in
            for (key, _) in attributes {
                if attributeDictionary[key.rawValue] != nil {
                    attributeDictionary[key.rawValue]?.append(range)
                } else {
                    attributeDictionary[key.rawValue] = [range]
                }
            }
        }
        
        return attributeDictionary
    }
}

public extension Character {
    static func fromUnichar(_ c: unichar) -> Character? {
        guard let scalar = UnicodeScalar(c) else {
            return nil
        }
        return Character(scalar)
    }
}

public extension CharacterSet {
    func contains(_ c: unichar) -> Bool {
        if let unicodeScalar = UnicodeScalar(c) {
            return contains(unicodeScalar)
        } else {
            // Handle the case where the unichar is not a valid Unicode scalar
            return false
        }
    }
}

#if canImport(AppKit) && !targetEnvironment(macCatalyst) // AppKit is for macOS
@available(macOS 12.0, *)
public extension NSRange {
    func textRange(contentManager: NSTextContentManager) -> NSTextRange? {
        guard let startLoc = contentManager.location(
            contentManager.documentRange.location,
            offsetBy: self.location)
        else {
            assertionFailure(); return nil
        }
        
        guard let endLoc = contentManager.location(startLoc, offsetBy: self.length) else {
            assertionFailure(); return nil
        }
        
        return NSTextRange(location: startLoc, end: endLoc)
    }
}
#endif
