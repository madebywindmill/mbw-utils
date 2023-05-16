//
//  MBWServerInterface.swift
//
//  Created by John Scalo on 7/16/18.
//  Copyright © 2018-2022 Made by Windmill. All rights reserved.
//

import Foundation

let serverInterfaceAPITimeout = 90.0

open class MBWServerInterface : NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    public typealias RequestCompletionHandler = (
        _ jsonDictionary: JSONObject?,
        _ response: HTTPURLResponse?,
        _ error: NSError?
        ) -> Void

    // Clients should consider using ErrorCompletionHandler from Types instead.
    public typealias BasicCompletionHandler = (_ error: NSError?) -> Void
    public typealias BasicErrorCompletionHandler = (_ error: Error?) -> Void

    public enum RequestOptions: String {
        case nonMainCompletion = "nonMainCompletion" // Completions are sent on the main thread by default. If you don't want that, set this.
        case formEncodeData = "formEncodeData"
        case customBaseURL = "customBaseURL" // overrides self.baseURL
        case overrideURL = "overrideURL" // will be used instead of prescribed endpoint
        case skipAuthHeader = "skipAuthHeader" // won't set Authorization header when set
        case none = "none"
    }
    
    public struct Notifications {
        static public let authMissingShouldSignOutNotification = NSNotification.Name(rawValue: "authMissingShouldSignOutNotification")
    }
    
    public enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case delete = "DELETE"
        case put = "PUT"
        case patch = "PATCH"
    }
    
    open var baseURL: URL!
    
    // Set for Bearer Token auth
    public var accessToken: String?

    public var enableDebugLogging = false
    
    // Set regex replacements here to redact private data in the logs.
    // E.g.: ["\"phoneNum\" : \".*\"": "\"phoneNum\" : \"<private>\""]
    public var debugLoggingRegexReplacements = [String:String]()
    
    // Set both for Basic auth
    public var basicUsername: String?
    public var basicPassword: String?
    
    static public let insertedArrayKey = "<insertedArrayKey>"
    static public let insertedDataKey = "<insertedDataKey>"

    convenience public init(accessToken: String) {
        self.init()
        self.accessToken = accessToken
    }
    
    @available(iOS 13.0.0, macOS 12.0.0, *)
    @discardableResult public func sendRequest(endpoint: String,
                     payload: Any!,
                     httpHeaders: [String:Any]? = nil,
                     queryPairs: [URLQueryItem] = [],
                     options: Dictionary<RequestOptions, Any>? = nil,
                     httpMethod: HTTPMethod) async throws -> (JSONObject?, HTTPURLResponse?) {
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<(JSONObject?, HTTPURLResponse?),Error>) in
        
            // Bypass main thread completion default.
            var fixedOptions = options ?? [RequestOptions:Any]()
            fixedOptions[.nonMainCompletion] = true

            self.sendRequest(endpoint: endpoint,
                        payload: payload,
                        httpHeaders: httpHeaders,
                        queryPairs: queryPairs,
                        options: fixedOptions,
                        httpMethod: httpMethod) { (json, response, error) in
                
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: (json, response))
                }
            }
        }
    }

    public func sendRequest(endpoint: String,
                     payload: Any!,
                     httpHeaders: [String:Any]? = nil,
                     queryPairs: [URLQueryItem] = [],
                     options: Dictionary<RequestOptions, Any>? = nil,
                     httpMethod: HTTPMethod,
                     completion: RequestCompletionHandler?) {
        
        // By default we send completions on the main thread but the caller can change this with RequestOptions.nonMainCompletion
        var actualCompletion: RequestCompletionHandler?
        if completion != nil {
            if let options = options, let b = options[.nonMainCompletion] as? Bool, b == true {
                actualCompletion = completion
            } else {
                actualCompletion = {(jsonDictionary, response, error) in
                    mainAsync {
                        completion!(jsonDictionary, response, error)
                    }
                }
            }
        }
                
        let unwrappedOptions = options ?? [.none : ""]

        // Set up the URL
        var url: URL?
        
        if let overrideURL = unwrappedOptions[.overrideURL] as? URL {
            url = overrideURL
        } else if let customBaseURL = unwrappedOptions[.customBaseURL] as? URL {
            url = (customBaseURL as NSURL).appendingPathComponent(endpoint)
        } else {
            url = (self.baseURL as NSURL).appendingPathComponent(endpoint)
        }

        // Add query strings, if any
        url = url?.appending(queryPairs: queryPairs)
        
        if url == nil {
            Logger.fileLog("*** Couldn't create URL. Bad chars?")
            actualCompletion?(nil, nil, MBWServerInterfaceError(code: .unknown))
            return
        }
        
        var request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: serverInterfaceAPITimeout)
        request.httpMethod = httpMethod.rawValue
        
        // Add auth (basic, bearer, or none)
        if unwrappedOptions[.skipAuthHeader] == nil {
            serverInterfaceAddAuthHeaders(request: &request)
        }
        
        // Add the payload, if any
        if unwrappedOptions[.formEncodeData] != nil {
            self.addFormEncodedBody(payload: payload, request: &request)
        } else if let formData = payload as? MBWServerInterfaceFormData  {
            if !formData.isClosed {
                Logger.log("*** Warning: formData wasn't closed so ending boundary is missing. It will be added for you.")
                formData.close()
            }
            request.httpBody = formData.formData as Data
            request.setValue("multipart/form-data; boundary=\(formData.formBoundary)", forHTTPHeaderField: "Content-Type")
        } else {
            self.addJSONBody(payload: payload, request: &request)
        }
                
        // Add other http header fields
        if let httpHeaders = httpHeaders {
            for (key, value) in httpHeaders as! Dictionary<String, String> {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        // We might want to use a custom URLSession
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
        debugLog(request.fullDescription())
        if let formData = payload as? MBWServerInterfaceFormData {
            debugLog("FORM DATA: \(formData.description)")
        }
        
        // Set up the task
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                actualCompletion?(nil, nil, error as NSError?)
                return
            }
            
            let httpResponse = response as! HTTPURLResponse
            
            self.debugLog("⬇️ \(httpResponse.statusCode) returned for \(request.url!)")
            
            var jsonDict: JSONObject?
            if let data = data {
                jsonDict = data.jsonToDict()
                if jsonDict == nil {
                    if let a = data.jsonToArray() {
                        jsonDict = [MBWServerInterface.insertedArrayKey: a]
                    }
                }
                if let jsonDict = jsonDict {
                    let jsonStr = jsonDict.jsonStr ?? "<null>"
                    self.debugLog("⬇️ JSON response:\n\(jsonStr)")
                } else {
                    self.debugLog("⬇️ Response not a JSON object")
                    // Not a dictionary and not an array, so drop back and insert the raw data.
                    jsonDict = [MBWServerInterface.insertedDataKey: data]
                }
            } else {
                self.debugLog("⬇️ Response data was empty")
            }
            
            // Treat http status codes above 300 as errors
            if httpResponse.statusCode >= 300 {
                
                if self.shouldDebugLog {
                    Logger.fileLog("*** server returned \(httpResponse.statusCode)")
                    if let data = data {
                        if let rawString = String(data: data, encoding: String.Encoding.utf8) {
                            Logger.fileLog("*** raw response string: \(rawString)")
                        }
                    }
                }
                
                actualCompletion?(jsonDict, httpResponse, MBWServerInterfaceError.forHTTPStatus(httpResponse.statusCode))
                return
            }
            
            actualCompletion?(jsonDict, httpResponse, nil)
        }
        
        // And start it
        debugLog("⬆️ requesting: \(httpMethod.rawValue) \(request.url!)")
        
        task.resume()
    }
    
    // Redirects will strip our auth header. Re-add it here.
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        debugLog("➡️ redirecting: \(String(describing: request.url))")
        if request.allHTTPHeaderFields?["rToken"] != nil && request.allHTTPHeaderFields?["Authorization"] == nil {
            
            var newRequest = URLRequest(url: request.url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: serverInterfaceAPITimeout)
            newRequest.httpBody = request.httpBody
            newRequest.httpMethod = request.httpMethod
            newRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
            self.serverInterfaceAddAuthHeaders(request: &newRequest)
            completionHandler(newRequest)
        }
    }
    
    private func addJSONBody(payload: Any!, request: inout URLRequest) {
        if payload == nil {
            return
        }
        
        // The caller has the option of sending a property list type (dict, array) or JSON data.
        if payload is Data {
            request.httpBody = payload as? Data
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } else {
            if let json = Data.objectToJSON(payload!) {
                request.httpBody = json
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
    }
    
    private func addFormEncodedBody(payload: Any!, request: inout URLRequest) {
        guard let dict = payload as? JSONObject else {
            Logger.fileLog("*** couldn't cast payload as dictionary")
            return
        }
        
        var params = ""
        for (key,value) in dict {
            if !params.isEmpty {
                params += "&"
            }
            
            let strValue = "\(value)"
            
            if let escapedValue = strValue.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
                params += "\(key)=\(escapedValue)"
            } else {
                Logger.fileLog("*** couldn't percent escape")
            }
        }
        
        request.httpBody = params.data(using: String.Encoding.ascii)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }
    
    private func serverInterfaceAddAuthHeaders(request: inout URLRequest) {
        if let accessToken = self.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else if let basicUsername = self.basicUsername, let basicPassword = self.basicPassword {
            guard let str = "\(basicUsername):\(basicPassword)".base64Encoded() else {
                Logger.fileLog("*** base64 failed")
                return
            }
            request.setValue("Basic \(str)", forHTTPHeaderField: "Authorization")
        }
    }
    
    private var shouldDebugLog: Bool {
        var isDebugBuild = false
        #if DEBUG
        isDebugBuild = true
        #endif
        return isDebugBuild || enableDebugLogging
    }
    
    private func debugLog(_ str: String) {
        if !shouldDebugLog {
            return
        }
        var strCopy = str
        for (key, val) in self.debugLoggingRegexReplacements {
            strCopy = strCopy.replacingOccurrences(
                of: key,
                with: val,
                options: .regularExpression)
        }
        Logger.fileLog(strCopy)
    }
}

public extension URLRequest {
    func fullDescription() -> String {
        var s = "\n---\n"
        if let url = self.url, let method = self.httpMethod {
            s += ("\(method): \(url)\n")
        }
        if let data = self.httpBody, let str = String(data: data, encoding: .utf8) {
            s += ("BODY: \(str)\n")
        }
        if let headers = self.allHTTPHeaderFields {
            s += "HEADERS: "
            for (key,value) in headers {
                s += "[\(key): \(value)] "
            }
            s += "\n"
        }
        s += "---\n"
        return s
    }
    
    func printFullDescription() {
        print(self.fullDescription())
    }
}

public extension URL {
    func appending(queryPairs: [URLQueryItem]) -> URL? {
        if queryPairs.isEmpty {
            return self
        } else {
            var newURL: URL? = self
            
            for nextPair in queryPairs {
                let urlStr = String(format: "%@%@%@=%@", newURL!.absoluteString, newURL!.query != nil ? "&" : "?", nextPair.name, nextPair.value!)
                newURL = URL(string: urlStr)
                if newURL == nil {
                    return nil
                }
            }
            
            return newURL
        }
    }
}

public class MBWServerInterfaceFormData: CustomStringConvertible {
    var formData = NSMutableData()
    let formBoundary = "Boundary-\(UUID().uuidString)"
    var isClosed = false
    
    // Used only for the description
    var debugFields = JSONObject()

    public var description: String {
        return debugFields.jsonStr ?? "<nil>"
    }

    public init() {}

    public func addField(name: String, value: Any) {
        var fieldString = "--\(formBoundary)\r\n"
        fieldString += "Content-Disposition: form-data; name=\"\(name)\"\r\n"
        fieldString += "\r\n"
        fieldString += "\(value)\r\n"

        formData.appendString(fieldString)
        debugFields[name] = value
    }
    
    public func addFile(fileName: String, fieldName: String, mimeType: String, fileData: Data) {
        let data = NSMutableData()
        
        data.appendString("--\(formBoundary)\r\n")
        data.appendString("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        data.appendString("Content-Type: \(mimeType)\r\n\r\n")
        data.append(fileData)
        data.appendString("\r\n")
        
        formData.append(data as Data)
        debugFields[fieldName] = "<file data of length \(fileData.count)>; <mime-type: \(mimeType)>; <filename: \(fileName)>"
    }
    
    public func close() {
        formData.appendString("--\(formBoundary)--")
        isClosed = true
    }
}

public extension NSMutableData {
    func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        } else {
            assertionFailure()
        }
    }
}

public class MBWServerInterfaceError: NSError {
    static public let domain = "MBWServerInterfaceError"
    static public let httpDomain = "MBWServerInterfacHTTPErrorDomain"

    @objc(MBWServerInterfaceErrorCodes) public enum Codes: Int {
        case unknown, invalidConfiguration
    }

    static private func descriptionForCode(_ code: Codes) -> String {
        switch code {
            case .unknown: return "Unknown"
            case .invalidConfiguration: return "Invalid Configuration"
        }
    }
    
    public convenience init(code: MBWServerInterfaceError.Codes) {
        let desc = MBWServerInterfaceError.descriptionForCode(code)
        self.init(domain: MBWServerInterfaceError.domain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: desc])
    }

    static public func forHTTPStatus(_ status: Int) -> NSError {
        return NSError(domain: httpDomain, code: status, userInfo: [NSLocalizedDescriptionKey: "HTTP status \(status)"])
    }

}

public extension Error {
    func isHTTPStatusCode() -> Bool {
        let e = self as NSError
        return e.domain == MBWServerInterfaceError.httpDomain
    }
    
    var httpStatusCode: Int? {
        let e = self as NSError
        if e.domain == MBWServerInterfaceError.httpDomain {
            return e.code
        } else {
            return nil
        }
    }
}
