//
//  JSONObject.swift
//  
//
//  Created by John Scalo on 8/26/21.
//

import Foundation

public typealias JSONObject = [String:Any]
public typealias JSONArray = [JSONObject]

public let gJSONObjectLock = UnfairLock()

public extension JSONObject {
    
    init?(string: String) {
        guard let data = string.data(using: .utf8) else { return nil }
        self.init(data: data)
    }
    
    init?(data: Data) {
        do {
            guard let json = try JSONSerialization.jsonObject(
                    with: data,
                    options: JSONSerialization.ReadingOptions(rawValue: 0)
            ) as? JSONObject else {
                return nil
            }
            self = json
        } catch {
            Logger.log("*** error from JSONSerialization: \(error)")
            return nil
        }
    }
    
    // This should probably be deprecated in favor of init(data:).
    static func fromData(_ data: Data) throws -> JSONObject {
        let jsonDict = try JSONSerialization.jsonObject(
                with: data,
                options: JSONSerialization.ReadingOptions(rawValue: 0)
            ) as? JSONObject
        
        guard let jsonDict = jsonDict else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSPropertyListReadCorruptError)
        }
        
        return jsonDict
    }
    
    /// Recursively enumerate all JSONObject values in the current JSON structure, repeatedly calling the closure `block` for each object.
    func enumerateObjects(_ block: (_ object: JSONObject)->Void) {
        for v in self.values {
            if let d = v as? JSONObject {
                block(d)
                d.enumerateObjects(block)
            } else if let a = v as? JSONArray {
                a.forEach {
                    block($0)
                    $0.enumerateObjects(block)
                }
            }
        }
    }

    /// Recursively enumerate all JSONArray values in the current JSON structure, repeatedly calling the closure `block` for each object.
    func enumerateArrays(_ block: (_ array: JSONArray)->Void) {
        for v in self.values {
            if let a = v as? JSONArray {
                block(a)
                a.forEach {
                    $0.enumerateArrays(block)
                }
            } else if let d = v as? JSONObject {
                d.enumerateArrays(block)
            }
        }
    }
    
    /// Retrieve a value from a nested JSON structure by following a specified path, where the keys are separated by `/`. This works fine as long as every non-leaf node is a dictionary (`JSONObject`) but would need some updating to also support arrays (`JSONArray`). Access is thread-safe manner via a Darwin lock.
    func getValue(at path: String) -> Any? {
        var pathComps = path.components(separatedBy: "/")
        var returnValue: Any?
        
        gJSONObjectLock.locked {
            var currentJSON = self
            while !pathComps.isEmpty {
                let nextPathComp = pathComps.removeFirst()
                if pathComps.isEmpty {
                    returnValue = currentJSON[nextPathComp]
                    break
                } else {
                    guard let nextJSON = currentJSON[nextPathComp] as? JSONObject else {
                        print("*** not a JSON object")
                        break
                    }
                    currentJSON = nextJSON
                }
            }
        }
        
        return returnValue
    }
}

