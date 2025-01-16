//
//  SimpleNSStringParser.swift
//  Sonar
//
//  Created by John Scalo on 1/17/24.
//  Copyright © 2024 Made by Windmill LLC. All rights reserved.
//

import Foundation

/// Generally there are three flavors of parsing:
/// read() - try to read the given value from the current location and return that value, or nil if none found
/// readPast() - try to read up to and past the given value from the current location and return the value or nil if none found
/// readUntil() - try to read up to but not past the given value, and return the string read up to it
/// readUnitlNot() - keep reading until an element doesn't meet the criteria
/// testNext() - checks criteria at the next character but doesn't move the loc ptr
open class SimpleNSStringParser {
    public var loc = 0
    public var length: Int
    public var str: NSString
    
    public init(str: NSString) {
        self.str = str
        self.length = str.length
    }
    
    public func hasNext() -> Bool {
        return loc < length
    }
    
    // MARK: - Characters
    
    public func nextUnichar() -> unichar? {
        guard hasNext() else { return nil }
        let c = str.character(at: loc)
        loc += 1
        return c
    }

    /// I tried other more complicated versions of this that don't use substring but they weren't any faster.
    public func nextCharacter() -> Character? {
        guard hasNext() else { return nil }
        let range = NSRange(loc, 1)
        let character = str.substring(with: range)
        loc += 1
        return Character(character)
    }
    
    /// tries to read a single character belonging to the given charSet. if successful, advances the loc ptr and returns the scanned character.
    public func readCharIn(_ charSet: CharacterSet) -> Character? {
        guard hasNext() else { return nil }
        let c = str.character(at: loc)
        if charSet.contains(c) {
            loc += 1
            return Character.fromUnichar(c)
        } else {
            return nil
        }
    }
    
    /// reads until the given char is encountered and returns everything read until that point. location is advanced at the point _after_ the given char. if stopBeforeNewline is true, it..uh..stops before the newline, otherwise it will continue scanning until EOF. Use `advanceAfter` as a convenience to advnace the loc ptr after the found character.
    public func readUntilCharacter(_ char: Character,
                   stopBeforeNewline: Bool = false,
                   advanceAfter: Bool = false) -> NSString? {
        var result = ""
        let startingLoc = loc
        if stopBeforeNewline {
            while let nextChar = nextCharacter(), nextChar != char, (nextChar.utf16.first ?? 0) != unicharLF {
                result.append(nextChar)
            }
        } else {
            while let nextChar = nextCharacter(), nextChar != char {
                result.append(nextChar)
            }
        }
        if startingLoc != loc && !advanceAfter {
            loc -= 1
        }
        return result.isEmpty ? nil : result.nsString
    }
    
    public func readUntilNotChar(_ char: Character, max: Int = Int.max) -> NSString? {
        var result = ""
        var cnt = 0
        while let nextChar = nextCharacter(), nextChar == char, cnt < max {
            result.append(nextChar)
            cnt += 1
        }
        // back up to loc before "not" char
        if cnt > 0 { loc -= 1 }
        return result.isEmpty ? nil : result.nsString
    }
    
    /// Reads until the scanned character is not in the given character set.
    /// - Parameter charSet: The character set that ends the search.
    /// - Parameter max: An optional max number of chars to read before ending the search.
    /// - Returns: readChar: the character not in charSet that ended the scanning. count: the number of characters read until readChar was encountered.
    /// On return, parser loc points at the locaiton just before the character in charSet.
    @discardableResult public func readUntilCharNotIn(_ charSet: CharacterSet,
                                               max: Int = Int.max) -> (readChar: Character, count: Int)? {
        var cnt = 0
        while loc < str.length, cnt < max {
            let c = str.character(at: loc)
            if !charSet.contains(c) {
                if let Char = Character.fromUnichar(c) {
                    return (Char, cnt)
                } else {
                    // Rare, but seen once.
                    print("*** bad character: \(c)")
                    return nil
                }
            }
            loc += 1
            cnt += 1
        }
        return nil
    }
        
    /// Same as above but returns entire scanned string and not just the last scanned character.
    @discardableResult public func readUntilNotIn(_ charSet: CharacterSet,
                                           max: Int = Int.max) -> NSString? {
        var cnt = 0
        let returnStr: NSMutableString = ""
        while loc < str.length, cnt < max {
            let c = str.character(at: loc)
            if !charSet.contains(c) {
                return returnStr
            }
            returnStr.append(String.fromUnichar(c))
            loc += 1
            cnt += 1
        }
        return returnStr.length > 0 ? returnStr : nil
    }

    /// reads up until any char in the given charSet (currently also past newlines!) and returns the result up to that point. also sets the inout foundChar to the character in the given charSet that was encountered.
    @discardableResult public func readUntilCharIn(_ charSet: CharacterSet,
                                      foundChar: inout Character,
                                      advanceAfter: Bool = false) -> NSString? {
        guard hasNext() else { return nil }
        var result = ""
        while loc < str.length {
            let c = str.character(at: loc)
            guard let char = Character.fromUnichar(c) else { continue }
            if charSet.contains(c) {
                foundChar = char
                return result.nsString
            } else {
                result.append(char)
                loc += 1
            }
        }
        if advanceAfter {
            loc += 1
        }
        return result.nsString
    }
    
    public func readUntilNot(_ char: unichar) -> NSString? {
        guard let c = UnicodeScalar(char) else { return nil }
        return readUntilNotChar(Character(c))
    }
    
    // MARK: - Strings

    @discardableResult public func readString(_ otherStr: NSString) -> NSString? {
        let searchRange = NSRange(location: loc, length: str.length - loc)
        // using NSString.range(of:) is faster than NSString.substring
        let foundRange = str.range(of: otherStr as String, options: .anchored, range: searchRange)

        if foundRange.location != NSNotFound {
            loc += otherStr.length
            return otherStr
        } else {
            return nil
        }
    }
    
    /// tries to read any of the given strings from the current position. if successful, advances the loc ptr and returns the scanned string, with the foundString param being set to the string that was matched.
    public func readAnyString(_ strs: [NSString]) -> NSString? {
        let savedLoc = loc
        for nextStr in strs {
            if let str = readString(nextStr) {
                return str
            }
            loc = savedLoc
        }
        return nil
    }
    
    @discardableResult public func readUntilString(_ string: NSString,
                         stopBeforeNewline: Bool = false,
                         advanceAfter: Bool = false) -> NSString? {
        var result = ""
        let searchString = string as String

        while let nextChar = nextCharacter() {
            result.append(nextChar)

            if result.hasSuffix(searchString) {
                let len = result.count - searchString.count
                if len > 0 {
                    result = result.substring(0..<len)
                } else {
                    result = ""
                }
                if !advanceAfter {
                    loc -= searchString.length
                }
                break
            }

            if stopBeforeNewline && (nextChar.utf16.first ?? 0) == unicharLF {
                break
            }
        }

        return result.nsString
    }
    
    @discardableResult public func readPastString(_ string: NSString) -> NSString? {
        guard let str1 = readUntilString(string) else { return nil }
        guard let str2 = readString(string) else { return nil }
        return (str1.string + str2.string).nsString
    }
    
    public func readUntilEOF() -> NSString {
        guard loc < str.length else { return "" }
        return str.substring(with: NSRange(loc, str.length - loc)).nsString
    }
    
    // MARK: - Numbers
    
    @discardableResult public func readInt() -> Int? {
        guard str.length > 0 else { return nil }
        var numString = ""

        while loc < str.length {
            let charRange = NSRange(loc, 1)
            let currentChar = str.substring(with: charRange)

            if Character(currentChar).isNumber {
                numString += currentChar
                loc += 1
            } else {
                break
            }
        }

        guard let number = Int(numString) else {
            return nil
        }
        
        return number
    }

    public func testNext(_ any: [NSString]) -> NSString? {
        guard let substr = self.str.remainingPartOfLine(from: loc) else {
            return nil
        }
        for s in any {
            if substr.hasPrefix(s) {
                return s
            }
        }
        return nil
    }
    
    public func testNextCharIn(_ charSet: CharacterSet) -> Character? {
        guard hasNext() else { return nil }
        let c = str.character(at: loc)
        if charSet.contains(c) {
            return Character.fromUnichar(c)
        } else {
            return nil
        }
    }
    
    // skip past spaces and tabs, but not newlines. returns count of white space chars skipped.
    @discardableResult public func skipWhitespace(max: Int = Int.max) -> Int {
        var cnt = 0
        while loc < str.length, cnt < max {
            let c = str.character(at: loc)
            if c == unicharSpace || c == unicharTab {
                loc += 1
                cnt += 1
            } else {
                break
            }
        }
        return cnt
    }
}

// MARK: - Link parsing
public extension SimpleNSStringParser {
    
    /// link-text: <[><chars min=0><]>
    /// allowLeadingWhitespace should only be true when parsing from the beginning of a line
    func parseLinkText(allowLeadingWhitespace: Bool) -> String? {
        guard hasNext() else { return nil }
        if allowLeadingWhitespace {
            readUntilCharNotIn(whitespaceCharSet, max: 3)
        }
        guard nil != readString("[") else { return nil }
        guard let text = readUntilCharacter("]", advanceAfter: true) else { return nil }
        return text.string.trimmingWhitespace
    }

    /// link-label: <[><chars min=1><]>
    /// allowLeadingWhitespace should only be true when parsing from the beginning of a line
    func parseLinkLabel(allowLeadingWhitespace: Bool) -> String? {
        guard hasNext() else { return nil }
        if allowLeadingWhitespace {
            readUntilCharNotIn(whitespaceCharSet, max: 3)
        }
        guard nil != readString("[") else { return nil }
        guard let text = readUntilCharacter("]", advanceAfter: true) else { return nil }
        // verify text has at least one non-newline non-whitespace character
        guard text.rangeOfCharacter(from: nonWhitespaceAndNewlinesCharSet, range: text.wholeRange).location != NSNotFound else { return nil }
        return text.string.trimmingWhitespace
    }
    
    /// link-destination: either of
    /// * <\<><chars min=0, no newlines><\>>
    /// * <chars with no spaces or ascii control chars, min=1>
    /// * <(><chars with no spaces or ascii control chars min=1><)>
    // precompile for performance:
    static let parseLinkDestinationAllowedCharSet = CharacterSet.controlCharacters.union(CharacterSet([" "])).inverted.union(CharacterSet(["/"]))
    func parseLinkDestination() -> String? {
        if let openingDel = readCharIn(["<", "("]) {
            var closingDel = Character("x")
            if openingDel == "(" {
                closingDel = ")"
            } else if openingDel == "<" {
                closingDel = ">"
            }
            guard let text = readUntilCharacter(closingDel, advanceAfter: true) else { return nil }
            return text.string.trimmingWhitespace
        } else {
            // handle format where there are no delimiters. requires at least 1 char with no spaces or ascii control chars. apparently also "/" allowed, for "/url".
            guard let text = readUntilNotIn(Self.parseLinkDestinationAllowedCharSet) else { return nil }
            guard text.length > 0 else { return nil }
            return text.string
        }
    }

    /// link-title: <", ', or (><characters min=1><", ', or )>
    func parseLinkTitle() -> String? {
        skipWhitespace()
        guard let openingDel = readCharIn(["\"", "'", "("]) else { return nil }
        let closingDel = openingDel == "(" ? ")" : openingDel
        guard let text = readUntilCharacter(closingDel, advanceAfter: true) else { return nil }
        guard text.length > 0 else { return nil }
        return text.string
    }
}

