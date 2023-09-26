//
//  File.swift
//  
//
//  Created by John Scalo on 9/26/23.
//

import Foundation

public extension MBWServerInterface {
    enum LogOption {
        case endpoint, responseBody, header, error, all
        case any // not for client use
    }

    func debugLog(_ str: String, logType: LogOption, force: Bool = false) {
        guard force || hasLogOption(logType) else { return }
        var strCopy = str
        for (key, val) in self.debugLoggingRegexReplacements {
            strCopy = strCopy.replacingOccurrences(
                of: key,
                with: val,
                options: .regularExpression)
        }
        Logger.fileLog(strCopy, options: [.noFileInfo])
    }
    
    func hasLogOption(_ option: LogOption) -> Bool {
        return logOptions.hasOption(option)
    }

}

public extension URLRequest {
    
    func descriptionForLoggingOptions(_ options: [MBWServerInterface.LogOption]) -> String? {
        guard !options.isEmpty else {
            return nil
        }
        // This isn't an error so if that's the only type of logging option, return nil
        if options.count == 1 && options.first == .error {
            return nil
        }
        var s = ""
        if options.hasOption(.endpoint) {
            if let url = self.url, let method = self.httpMethod {
                s += ("⬆️ \(method): \(url)\n")
            }
        }
        if options.hasOption(.responseBody) {
            if let data = self.httpBody, let str = String(data: data, encoding: .utf8) {
                s += ("🖊️ BODY: \(str)\n")
            }
        }
        if options.hasOption(.header) {
            if let headers = self.allHTTPHeaderFields {
                s += "📋 HEADERS: "
                for (key,value) in headers {
                    s += "[\(key): \(value)] "
                }
                s += "\n"
            }
        }
        return s
    }
    
    
    func printFullDescription() {
        print(self.descriptionForLoggingOptions([.all]) ?? "<nil>")
    }
}

extension [MBWServerInterface.LogOption] {
    func hasOption(_ option: MBWServerInterface.LogOption) -> Bool {
        return self.contains(.all) || self.contains(option)
    }
}
