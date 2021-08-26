//
//  JSONObject.swift
//  
//
//  Created by John Scalo on 8/26/21.
//

import Foundation

public typealias JSONObject = [String:Any]
public typealias JSONArray = [JSONObject]

public extension JSONObject {
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
}

