//
//  FoundationExtras.swift
//
//  Created by John Scalo on 12/21/17.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

import Foundation

public extension Date {
    
    static func fromISO8601String(_ str: String) -> Date? {
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
    
    var year: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        return dateFormatter.string(from: Date())
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

    func ISO8601String() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        return formatter.string(from: self)
    }

    /// RFC 2616 dates are typically used in HTTP headers.
    static func fromRFC2616String(_ str: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        return dateFormatter.date(from: str)
    }
    
    func isAfterDate(_ date: Date) -> Bool {
        return self.compare(date) == .orderedDescending
    }
    
    func isBeforeDate(_ date: Date) -> Bool {
        return self.compare(date) == .orderedAscending
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
    
    @available(iOS 15, macOS 12.0, watchOS 8, *)
    func friendlyTimeString(includeTime: Bool = true) -> String {
        if Calendar.current.isDateInToday(self) {
            return "Today\(includeTime ? (" at " + formatted(date: .omitted, time: .shortened)) : "")"
        } else if Calendar.current.isDateInYesterday(self) {
            return "Yesterday\(includeTime ? (" at " + formatted(date: .omitted, time: .shortened)) : "")"
        } else {
            return formatted(date: .abbreviated, time: includeTime ? .shortened : .omitted)
        }
    }
    
    @available(iOS 15, macOS 12.0, watchOS 8, *)
    func humanReadableTimeFrameSinceNow() -> String {
        let seconds = abs(self.timeIntervalSinceNow)
        
        if seconds < 60 {
            // less than 60 seconds
            return NSLocalizedString("Just Now", comment: "")
        } else if seconds < 60*60 {
            // less than 60 minutes
            let minutes = Int(seconds/60)
            if minutes == 1 {
                return String(minutes) + NSLocalizedString(" Min Ago", comment: "")
            } else {
                return String(minutes) + NSLocalizedString(" Mins Ago", comment: "")
            }
        } else if seconds < 60*60*24 {
            // less than 24 hours
            let hours = Int(seconds/60/60)
            if hours == 1 {
                return String(hours) + NSLocalizedString(" Hour Ago", comment: "")
            } else {
                return String(hours) + NSLocalizedString(" Hours Ago", comment: "")
            }
        } else {
            // days
            return formatted(date: .abbreviated, time: .shortened)
        }
        
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
    
    var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self)
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

    var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self)
    }

    func prettyPrint() {
        if let str = self.jsonStr {
            print(str)
        } else {
            print("<error>")
        }
    }
}

public extension Array where Element: Equatable {
    func containsAnyOf(_ elements: [Element]) -> Bool {
        for element in elements {
            if self.contains(element) {
                return true
            }
        }
        return false
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
    
    static func cachedDataFrom(url: URL, authorizationHeader: [String:String]? = nil) -> Data? {
        var request = URLRequest(url: url, cachePolicy: .returnCacheDataDontLoad, timeoutInterval: 10.0)
        if let authorizationHeader {
            for key in authorizationHeader.keys {
                request.setValue(authorizationHeader[key], forHTTPHeaderField: key)
            }
        }
        if let data = URLCache.shared.cachedResponse(for: request)?.data {
            return data
        } else {
            return nil
        }
    }
    
    @available(iOS 13, macOS 12.0, watchOS 6, *)
    static func from(url: URL, returnCachedDataIfAvailable: Bool = true, authorizationHeader: [String:String]? = nil, cachePolicy: NSURLRequest.CachePolicy = .useProtocolCachePolicy) async throws -> Data {
        if returnCachedDataIfAvailable, let data = Data.cachedDataFrom(url: url, authorizationHeader: authorizationHeader) {
            return data
        } else {
            var request = URLRequest(url: url, cachePolicy: cachePolicy, timeoutInterval: 10.0)
            if let authorizationHeader {
                for key in authorizationHeader.keys {
                    request.setValue(authorizationHeader[key], forHTTPHeaderField: key)
                }
            }
            let (data, urlResponse) = try await URLSession.shared.data(for: request)
            if let urlResponse = urlResponse as? HTTPURLResponse, urlResponse.statusCode == 403 {
                throw NSError(domain: NSURLErrorDomain, code: NSURLErrorUserAuthenticationRequired)
            }
            return data
        }
    }

    var imageFileExtension: String {
        var values = [UInt8](repeating:0, count:1)
        self.copyBytes(to: &values, count: 1)

        let ext: String
        switch (values[0]) {
        case 0xFF:
            ext = ".jpg"
        case 0x89:
            ext = ".png"
        case 0x47:
            ext = ".gif"
        case 0x49, 0x4D :
            ext = ".tiff"
        default:
            ext = ".png"
        }
        return ext
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

public extension Optional where Wrapped == String {
    var nonNil: String {
        return self ?? ""
    }
}

public extension Optional {
    var optionalDesc: String {
        switch self {
        case .some(let value):
            return "\(value)"
        case .none:
            return "<nil>"
        }
    }
}

@available(iOS 13, macOS 12.0, watchOS 6, *)
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

public extension UUID {
    static func short(prefix: String = "", length: Int = 12) -> String {
        return "\(prefix)\(String.random(length: length))"
    }

}

public func addressString(of obj: AnyObject) -> String {
    return "\(Unmanaged.passUnretained(obj).toOpaque())"
}

public extension CGRect {
    func isAdjacentTo(_ r2: CGRect) -> Bool {
        if self.intersects(r2) {
            return true
        }

        let deltaY = abs(r2.origin.y - self.maxY)
        if deltaY <= 0.001 {
            return true
        }

        return false
    }
}

public extension ClosedRange {
    func clamp(_ value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

public extension Range where Bound == String.Index {
    func location(in string: String) -> Int {
        return string.distance(from: string.startIndex, to: self.lowerBound)
    }
    
    func length(in string: String) -> Int {
        return string.distance(from: self.lowerBound, to: self.upperBound)
    }
}

public extension NSRange {
    init(_ loc: Int, _ len: Int) {
        self.init(location: loc, length: len)
    }
    
    var start: Int {
        return location
    }
    
    var end: Int {
        return location + length
    }
}
