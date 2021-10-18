//
//  MBWLogger.swift
//
//  Created by John Scalo on 7/16/18.
//  Copyright © 2018-2021 Made by Windmill. All rights reserved.
//

import Foundation

private let mbwLoggerQ = DispatchQueue(label: "MBWLoggerQueue")

public class Logger {

    public class func log(_ str: String, file: String = #file, line: Int = #line, function: String = #function) {
        #if DEBUG
        let shortenedFile = file.components(separatedBy: "/").last ?? ""
        let s = "[\(shortenedFile):\(function):\(line)] \(str)"
        NSLog(s)
        #endif
    }
    
    public class func shortLog(_ str: String) {
        #if DEBUG
        print(str)
        #endif
    }
    
    public static var debugFileURL: URL {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: MBWConstants.appGroupIdentifier)!
        return url.appendingPathComponent("debugLog.txt")
    }

    public static var maxBytes: Int = 200000
    public static var snipInterval: TimeInterval = 3600
    
    private static let formatter = DateFormatter()
    public class func fileLog(_ str: String, file: String = #file, line: Int = #line, function: String = #function, debugOnly: Bool = false) {
        
        let shortenedFile = file.components(separatedBy: "/").last ?? ""
        
        #if UNIT_TEST
        self.log(str, file: shortenedFile, line: line, function: function)
        return
        #endif
        
        #if !DEBUG
        if debugOnly {
            return
        }
        #endif
        
        if shouldSnip() {
            snip()
        }
        
        if formatter.dateFormat != "yyyy-MM-dd HH:mm:ss ZZZ" {
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        }
        let dateStr = formatter.string(from: Date())
        let s = "\(dateStr) [\(shortenedFile):\(function):\(line)] \(str)"
        let strForNSLog = "[\(shortenedFile):\(function):\(line)] \(str)"
        NSLog(strForNSLog)
        
        mbwLoggerQ.async {
            if !FileManager.default.fileExists(atPath: debugFileURL.path) {
                FileManager.default.createFile(atPath: debugFileURL.path, contents: nil, attributes: nil)
            }
            
            do {
                let logFile = try FileHandle(forUpdating: debugFileURL)
                if let data = "\(s)\n".data(using: String.Encoding.utf8) {
                    logFile.seekToEndOfFile()
                    logFile.write(data)
                    logFile.closeFile()
                }
            } catch {
                NSLog("*** Caught: \(error)")
            }
        }
    }
    
    public class func logForEmail() -> String {
        if !FileManager.default.fileExists(atPath: debugFileURL.path) {
            return "(No debug logs found)"
        }
        
        guard let data = try? Data(contentsOf: debugFileURL) else {
            return "(Data error)"
        }
        
        guard let str = String(data: data, encoding: String.Encoding.utf8) else {
            return "(String error)"
        }
        
        return str
    }
    
    public class func clear() {
        try? FileManager.default.removeItem(at: debugFileURL)
    }
    
    private class func shouldSnip() -> Bool {
        return abs(UserDefaults.standard.lastLogRollDate.timeIntervalSinceNow) > snipInterval
    }
    
    private class func snip() {
        mbwLoggerQ.async {
            guard let data = try? Data(contentsOf: debugFileURL) else {
                return
            }
            
            let length = data.count
            if length < maxBytes {
                return
            }
            
            let start = length - maxBytes
            let newData = data.subdata(in: start..<length)
            
            do {
                try newData.write(to: debugFileURL, options: .atomic)
            } catch {
                NSLog("*** Caught: \(error)")
            }
            
            UserDefaults.standard.lastLogRollDate = Date()
        }
    }
}

public extension UserDefaults {
    var lastLogRollDate: Date {
        get {
            return self.object(forKey: "MBWLoggerLastRollDate") as? Date ?? Date.distantPast
        }
        set(v) {
            self.set(v, forKey: "MBWLoggerLastRollDate")
            self.synchronize()
        }
    }
}
