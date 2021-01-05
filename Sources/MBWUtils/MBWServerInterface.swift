//
//  MBWServerInterface.swift
//
//  Created by John Scalo on 7/16/18.
//  Copyright © 2018-2021 Made by Windmill. All rights reserved.
//

import Foundation

let serverInterfaceAPITimeout = 90.0

open class MBWServerInterface : NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    
    public typealias RequestCompletionHandler = (
        _ jsonDictionary: Dictionary<String,Any>?,
        _ response: HTTPURLResponse?,
        _ error: NSError?
        ) -> Void

    public typealias BasicCompletionHandler = (_ error: NSError?) -> Void

    public enum RequestOptions: String {
        case queryPairs = "queryPairs"
        case headerFields = "headerFields"
        case nonMainCompletion = "nonMainCompletion" // Completions are sent on the main thread by default. If you don't want that, set this.
        case formEncodeData = "formEncodeData"
        case customBaseURL = "customBaseURL" // overrides self.baseURL
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
    
    // Set both for Basic auth
    public var basicUsername: String?
    public var basicPassword: String?
    
    static public let insertedArrayKey = "<mbwInsertedArrayKey>"
    static public let insertedDataKey = "<mbwInsertedDataKey>"

    convenience public init(accessToken: String) {
        self.init()
        self.accessToken = accessToken
    }
    
    public func sendRequest(endpoint: String,
                     payload: Any!,
                     options: Dictionary<RequestOptions, Any>? = nil,
                     httpMethod: HTTPMethod,
                     completion: RequestCompletionHandler?) {
        
        // By default we send completions on the main thread but the caller can change this with serverInterfaceNonMainCompletionKey
        var actualCompletion: RequestCompletionHandler?
        if completion != nil {
            if options?[.nonMainCompletion] != nil {
                actualCompletion = completion
            } else {
                actualCompletion = {(jsonDictionary, response, error) in
                    DispatchQueue.main.async {
                        completion!(jsonDictionary, response, error)
                    }
                }
            }
        }
            
        let unwrappedOptions = options ?? [.none : ""]

        // Set up the URL
        var url: URL?
        if let customBaseURL = unwrappedOptions[.customBaseURL] as? URL {
            url = (customBaseURL as NSURL).appendingPathComponent(endpoint)
        } else {
            url = (self.baseURL as NSURL).appendingPathComponent(endpoint)
        }

        // Add query strings, if any
        if let queryPairs = unwrappedOptions[.queryPairs] as? [URLQueryItem] {
            url = url?.appending(queryPairs: queryPairs)
        }
        
        if url == nil {
            Logger.log("Couldn't create URL. Bad chars?")
            actualCompletion?(nil, nil, MBWServerInterfaceError(code: .unknown))
            return
        }
        
        var request = URLRequest(url: url!, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: serverInterfaceAPITimeout)
        request.httpMethod = httpMethod.rawValue
        
        // Add auth (basic, bearer, or none)
        serverInterfaceAddAuthHeaders(request: &request)
        
        // Add the payload, if any
        if unwrappedOptions[.formEncodeData] != nil {
            self.addFormEncodedBody(payload: payload, request: &request)
        } else {
            self.addJSONBody(payload: payload, request: &request)
        }
                
        // Add other http header fields
        if let httpHeaderFields = unwrappedOptions[.headerFields] {
            for (key, value) in httpHeaderFields as! Dictionary<String, String> {
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        // We might want to use a custom URLSession
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: nil)
        
        #if DEBUG
            request.printFullDescription()
        #endif
        
        // Set up the task
        let task = session.dataTask(with: request) { (data, response, error) in
            
            if error != nil {
                actualCompletion?(nil, nil, error as NSError?)
                return
            }
            
            let httpResponse = response as! HTTPURLResponse
            
            Logger.shortLog(">>> \(httpResponse.statusCode) returned for \(request.url!)")
            
            var jsonDict: [String:Any]?
            if let data = data {
                jsonDict = data.jsonToDict()
                if jsonDict == nil {
                    if let a = data.jsonToArray() {
                        jsonDict = [MBWServerInterface.insertedArrayKey: a]
                    }
                }
                if jsonDict == nil {
                    // Not a dictionary and not an array, so drop back and insert the raw data.
                    jsonDict = [MBWServerInterface.insertedDataKey: data]
                }
            }
            
            // Treat http status codes above 300 as errors
            if httpResponse.statusCode >= 300 {
                
                #if DEBUG
                    Logger.shortLog("*** server returned \(httpResponse.statusCode)")
                    if let data = data {
                        if let rawString = String(data: data, encoding: String.Encoding.utf8) {
                            Logger.shortLog("*** raw response string: \(rawString)")
                        }
                    }
                #endif
                
                actualCompletion?(jsonDict, httpResponse, MBWServerInterfaceError.forHTTPStatus(httpResponse.statusCode, responseData: data))
                return
            }
            
            actualCompletion?(jsonDict, httpResponse, nil)
        }
        
        // And start it
        Logger.shortLog(">>> requesting: \(httpMethod.rawValue) \(request.url!)")
        
        task.resume()
    }
    
    // Redirects will strip our auth header. Re-add it here.
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        Logger.log(">>> redirecting: \(String(describing: request.url))")
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
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        } else {
            if let json = Data.objectToJSON(payload!) {
                request.httpBody = json
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
    }
    
    private func addFormEncodedBody(payload: Any!, request: inout URLRequest) {
        guard let dict = payload as? Dictionary<String,Any> else {
            Logger.log("*** couldn't cast payload as dictionary")
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
                Logger.log("*** couldn't percent escape")
            }
        }
        
        request.httpBody = params.data(using: String.Encoding.ascii)
        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    }
    
    private func serverInterfaceAddAuthHeaders(request: inout URLRequest) {
        if let accessToken = self.accessToken {
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        } else if let basicUsername = self.basicUsername, let basicPassword = self.basicPassword {
            guard let str = "\(basicUsername):\(basicPassword)".base64Encoded() else {
                Logger.log("*** base64 failed")
                return
            }
            request.setValue("Basic \(str)", forHTTPHeaderField: "Authorization")
        }
    }
}

extension URLRequest {
    public func printFullDescription() {
        print("---")
        if let url = self.url, let method = self.httpMethod {
            print("\(method): \(url)")
        }
        if let data = self.httpBody, let str = String(data: data, encoding: .utf8) {
            print("BODY: \(str)")
        }
        if let headers = self.allHTTPHeaderFields {
            print("HEADERS: ", terminator: "")
            for (key,value) in headers {
                print("[\(key): \(value)] ", terminator: "")
            }
            print()
        }
        print("---")
    }
}

extension URL {
    public func appending(queryPairs: [URLQueryItem]) -> URL? {
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

public class MBWServerInterfaceError: NSError {
    static public let domain = "MBWServerInterfaceError"
    static public let httpDomain = "MBWServerInterfacHTTPErrorDomain"

    @objc(MBWServerInterfaceErrorCodes) public enum Codes: Int {
        case unknown = 0
    }

    static private func descriptionForCode(_ code: Codes) -> String {
        switch code {
        case .unknown: return "Unknown"
        }
    }
    
    public convenience init(code: MBWServerInterfaceError.Codes) {
        let desc = MBWServerInterfaceError.descriptionForCode(code)
        self.init(domain: MBWServerInterfaceError.domain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: desc])
    }

    static public func forHTTPStatus(_ status: Int, responseData: Data?) -> NSError {
        return NSError(domain: httpDomain, code: status, userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(status)"])
    }

}
