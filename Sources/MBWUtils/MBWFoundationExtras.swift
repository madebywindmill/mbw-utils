//
//  MBWFoundationExtras.swift
//
//  Created by John Scalo on 12/21/17.
//  Copyright © 2018-2021 Made by Windmill. All rights reserved.
//

import Foundation

extension Date {
    
    static public func fromISO8601String(str: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Try with fractional seconds and time zone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SZ"
        if let date = formatter.date(from: str) {
            return date
        }
        
        // Try with time zone only
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        if let date = formatter.date(from: str) {
            return date
        }
        
        // Try with fractional seconds only
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.S"
        if let date = formatter.date(from: str) {
            return date
        }
        
        // Try with no time zone, no fractional seconds
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: str)!
    }
    
    public func ISO8601String() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter.string(from: self)
    }
    
    public func isAfterDate(_ date: Date) -> Bool {
        return self.compare(date) == .orderedDescending
    }
    
    public func isBeforeDate(_ date: Date) -> Bool {
        return self.compare(date) == .orderedAscending
    }
    
    public var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    public var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    public var tomorrowMidnight: Date {
        var components = DateComponents()
        components.day = 1
        components.second = 0
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    public func isAM() -> Bool {
        let hour = Calendar.current.component(.hour, from: self)
        return hour < 12
    }
        
    public func addingDays(_ days: Int) -> Date {
        let comps = DateComponents(calendar: Calendar.current, day: days)
        return Calendar.current.date(byAdding: comps, to: self) ?? self
    }
    
    public func calendarDaysSince(_ otherDate: Date) -> Int {
        let calendar = Calendar.current

        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: otherDate)
        let date2 = calendar.startOfDay(for: self)

        let components = calendar.dateComponents([.day], from: date1, to: date2)

        return components.day ?? 0
    }
    
    public func localDesc() -> String {
        return self.description(with: .current)
    }
}

// usage: expr someDict.prettyPrint()
extension Dictionary {
    public func prettyPrint() {
        if #available(iOS 13.0, *) {
            if let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .withoutEscapingSlashes]) {
                print(String(data: data, encoding: .utf8) ?? "<error>")
            } else {
                print("<error>")
            }
        } else {
            if let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) {
                print(String(data: data, encoding: .utf8) ?? "<error>")
            } else {
                print("<error>")
            }
        }
    }
}

// usage: expr someArray.prettyPrint()
extension Array {
    public func prettyPrint() {
        if #available(iOS 13.0, *) {
            if let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .withoutEscapingSlashes]) {
                print(String(data: data, encoding: .utf8) ?? "<error>")
            } else {
                print("<error>")
            }
        } else {
            if let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) {
                print(String(data: data, encoding: .utf8) ?? "<error>")
            } else {
                print("<error>")
            }
        }
    }
}

extension Data {
    static public func objectToJSON(_ object: Any) -> Data? {
        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions(rawValue: UInt(0)))
        } catch {
            print("JSONSerialization failed with \(error)")
        }
        return jsonData
    }
    
    public func jsonToDict() -> Dictionary<String,AnyObject>? {
        var jsonDict: Dictionary<String,AnyObject>?
        do {
            jsonDict = try JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? Dictionary<String,AnyObject>
        } catch {
            print("JSON error: \(error)")
        }
        
        return jsonDict
    }
    
    public func jsonToArray() -> [Any]? {
        var array: [Any]?
        do {
            array = try JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? Array<Any>
        } catch {
            print("JSON error: \(error)")
        }
        
        return array
    }
    
    public func hexadecimal() -> String {
        let hexBytes = self.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }    
}

extension NSData {
    public func hexadecimal() -> NSString {
        var bytes = [UInt8](repeating: 0, count: length)
        getBytes(&bytes, length: length)
        
        let hexString = NSMutableString()
        for byte in bytes {
            hexString.appendFormat("%02x", UInt(byte))
        }
        
        return hexString
    }
}

extension String {
    public var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: self)
    }
    
    public var isAllNumbers: Bool {
        guard self.count > 0 else { return false }
        let nums: Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        return Set(self).isSubset(of: nums)
    }
    
    public func substring(from: Int?, to: Int?) -> String {
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
    
    public func substring(from: Int) -> String {
        return self.substring(from: from, to: nil)
    }
    
    public func substring(to: Int) -> String {
        return self.substring(from: nil, to: to)
    }
    
    public func substring(from: Int?, length: Int) -> String {
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
    
    public func substring(length: Int, to: Int?) -> String {
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
    
    public func index(offset: Int) -> String.Index {
        return self.index(self.startIndex, offsetBy: offset)
    }
    
    public func replacingCharacters(from characterSet: CharacterSet, with string: String) -> String {
        return self.components(separatedBy: characterSet).joined(separator: string)
    }

    public var trimmedWhitespace: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    public func removeSpaces() -> String {
        return self.replacingOccurrences(of: " ", with: "")
    }
    
    public func base64Encoded() -> String? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        return data.base64EncodedString()
    }
    
    public func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    public var trimmingWhiteSpace: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

extension Optional where Wrapped == String {
    public var nonNil: String {
        return self ?? ""
    }
}

extension URL {
    public func queryArguments() -> [String : AnyObject]? {
        var returnArgs = [String : AnyObject]()
        guard let query = self.query else {
            return nil
        }
        let parts = query.components(separatedBy: "&")
        for nextPart in parts {
            let subparts = nextPart.components(separatedBy: "=")
            if subparts.count >= 2 {
                let pt0 = subparts[0].removingPercentEncoding
                let pt1 = subparts[1].removingPercentEncoding
                guard pt0 != nil && pt1 != nil else {
                    continue
                }
                returnArgs[pt0!] = pt1! as AnyObject
            }
        }
        return returnArgs
    }
    
    public func addingQueryItem(_ queryItem: URLQueryItem) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? [URLQueryItem]()
        queryItems.append(queryItem)
        components?.queryItems = queryItems
        return components?.url
    }
}

extension Int {
    static public func randomInt(min: Int, max:Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
}

extension Bundle {
    public static var versionString: String {
        let infoDict = Bundle.main.infoDictionary!
        return infoDict["CFBundleShortVersionString"] as! String
    }
    
    public static var buildString: String {
        let infoDict = Bundle.main.infoDictionary!
        return infoDict["CFBundleVersion"] as! String
    }
    
    public static var build: Int {
        let infoDict = Bundle.main.infoDictionary!
        return Int(infoDict["CFBundleVersion"] as! String) ?? 0
    }
    
    public static var prettyVersionString: String {
        return "\(Bundle.versionString) (\(Bundle.buildString))"
    }
}


extension NSPointerArray {
    public func addObject(_ object: AnyObject?) {
        guard let strongObject = object else { return }

        let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
        addPointer(pointer)
    }

    public func insertObject(_ object: AnyObject?, at index: Int) {
        guard index < count, let strongObject = object else { return }

        let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
        insertPointer(pointer, at: index)
    }

    public func replaceObject(at index: Int, withObject object: AnyObject?) {
        guard index < count, let strongObject = object else { return }

        let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
        replacePointer(at: index, withPointer: pointer)
    }

    public func object(at index: Int) -> AnyObject? {
        guard index < count, let pointer = self.pointer(at: index) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue()
    }

    public func removeObject(at index: Int) {
        guard index < count else { return }

        removePointer(at: index)
    }
}
