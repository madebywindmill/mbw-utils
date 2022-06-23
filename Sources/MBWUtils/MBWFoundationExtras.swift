//
//  MBWFoundationExtras.swift
//
//  Created by John Scalo on 12/21/17.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

import Foundation

public extension Date {
    
    static func fromISO8601String(str: String) -> Date? {
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
        return formatter.date(from: str)
    }
    
    func ISO8601String() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter.string(from: self)
    }
    
    func isAfterDate(_ date: Date) -> Bool {
        return self.compare(date) == .orderedDescending
    }
    
    func isBeforeDate(_ date: Date) -> Bool {
        return self.compare(date) == .orderedAscending
    }
    
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    var tomorrowMidnight: Date {
        var components = DateComponents()
        components.day = 1
        components.second = 0
        return Calendar.current.date(byAdding: components, to: startOfDay)!
    }
    
    func isAM() -> Bool {
        let hour = Calendar.current.component(.hour, from: self)
        return hour < 12
    }
        
    func addingDays(_ days: Int) -> Date {
        let comps = DateComponents(calendar: Calendar.current, day: days)
        return Calendar.current.date(byAdding: comps, to: self) ?? self
    }
    
    func calendarDaysSince(_ otherDate: Date) -> Int {
        let calendar = Calendar.current

        // Replace the hour (time) of both dates with 00:00
        let date1 = calendar.startOfDay(for: otherDate)
        let date2 = calendar.startOfDay(for: self)

        let components = calendar.dateComponents([.day], from: date1, to: date2)

        return components.day ?? 0
    }
    
    func localDesc() -> String {
        return self.description(with: .current)
    }
}

public extension Dictionary {
    
    var jsonStr: String? {
        if #available(iOS 13.0, *) {
            if let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .withoutEscapingSlashes]) {
                return String(data: data, encoding: .utf8)
            } else {
                return nil
            }
        } else {
            if let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) {
                return String(data: data, encoding: .utf8)
            } else {
                return nil
            }
        }
    }
    
    func prettyPrint() {
        if let str = self.jsonStr {
            print(str)
        } else {
            print("<error>")
        }
    }
}

public extension Array {
    var jsonStr: String? {
        if #available(iOS 13.0, *) {
            if let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted, .withoutEscapingSlashes]) {
                return String(data: data, encoding: .utf8)
            } else {
                return nil
            }
        } else {
            if let data = try? JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted]) {
                return String(data: data, encoding: .utf8)
            } else {
                return nil
            }
        }
    }

    func prettyPrint() {
        if let str = self.jsonStr {
            print(str)
        } else {
            print("<error>")
        }
    }
}

public extension Data {
    static func objectToJSON(_ object: Any) -> Data? {
        var jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions(rawValue: UInt(0)))
        } catch {
            print("JSONSerialization failed with \(error)")
        }
        return jsonData
    }
    
    func jsonToDict() -> Dictionary<String,AnyObject>? {
        var jsonDict: Dictionary<String,AnyObject>?
        do {
            jsonDict = try JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? Dictionary<String,AnyObject>
        } catch {
            // These logs can be too much when this occurs commonly
//            print("JSON error: \(error)")
        }
        
        return jsonDict
    }
    
    func jsonToArray() -> [Any]? {
        var array: [Any]?
        do {
            array = try JSONSerialization.jsonObject(with: self, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? Array<Any>
        } catch {
            // These logs can be too much when this occurs commonly
//            print("JSON error: \(error)")
        }
        
        return array
    }
    
    func hexadecimal() -> String {
        let hexBytes = self.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }    
}

public extension NSData {
    func hexadecimal() -> NSString {
        var bytes = [UInt8](repeating: 0, count: length)
        getBytes(&bytes, length: length)
        
        let hexString = NSMutableString()
        for byte in bytes {
            hexString.appendFormat("%02x", UInt(byte))
        }
        
        return hexString
    }
}

public extension String {
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
    
    func substring(from: Int) -> String {
        return self.substring(from: from, to: nil)
    }
    
    func substring(to: Int) -> String {
        return self.substring(from: nil, to: to)
    }
    
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
    
    func index(offset: Int) -> String.Index {
        return self.index(self.startIndex, offsetBy: offset)
    }
    
    func replacingCharacters(from characterSet: CharacterSet, with string: String) -> String {
        return self.components(separatedBy: characterSet).joined(separator: string)
    }

    var trimmedWhitespace: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
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

    var trimmingWhiteSpace: String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
}

public extension Optional where Wrapped == String {
    var nonNil: String {
        return self ?? ""
    }
}

@available(iOS 13, macOS 11.0, *)
@available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
@available(macOS, deprecated: 12.0, message: "Use the built-in API instead")
public extension URLSession {
    func data(fromURL url: URL) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: url) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    continuation.resume(throwing: error)
                    return
                }
                
                continuation.resume(returning: (data, response))
            }
            
            task.resume()
        }
    }
}

public extension URL {
    func queryArguments() -> [String : AnyObject]? {
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
    
    func addingQueryItem(_ queryItem: URLQueryItem) -> URL? {
        var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
        var queryItems = components?.queryItems ?? [URLQueryItem]()
        queryItems.append(queryItem)
        components?.queryItems = queryItems
        return components?.url
    }
}

public extension Int {
    static func randomInt(min: Int, max:Int) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    }
}

public extension Bundle {
    static var versionString: String {
        let infoDict = Bundle.main.infoDictionary!
        return infoDict["CFBundleShortVersionString"] as! String
    }
    
    static var buildString: String {
        let infoDict = Bundle.main.infoDictionary!
        return infoDict["CFBundleVersion"] as! String
    }
    
    static var build: Int {
        let infoDict = Bundle.main.infoDictionary!
        return Int(infoDict["CFBundleVersion"] as! String) ?? 0
    }
    
    static var prettyVersionString: String {
        return "\(Bundle.versionString) (\(Bundle.buildString))"
    }
}


public extension NSPointerArray {
    func addObject(_ object: AnyObject?) {
        guard let strongObject = object else { return }

        let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
        addPointer(pointer)
    }

    func insertObject(_ object: AnyObject?, at index: Int) {
        guard index < count, let strongObject = object else { return }

        let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
        insertPointer(pointer, at: index)
    }

    func replaceObject(at index: Int, withObject object: AnyObject?) {
        guard index < count, let strongObject = object else { return }

        let pointer = Unmanaged.passUnretained(strongObject).toOpaque()
        replacePointer(at: index, withPointer: pointer)
    }

    func object(at index: Int) -> AnyObject? {
        guard index < count, let pointer = self.pointer(at: index) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(pointer).takeUnretainedValue()
    }

    func removeObject(at index: Int) {
        guard index < count else { return }

        removePointer(at: index)
    }
}

public func addressString(of obj: AnyObject) -> String {
    return "\(Unmanaged.passUnretained(obj).toOpaque())"
}

