//
//  MBWConstants.swift
//
//  Created by John Scalo on 1/5/21.
//  Copyright © 2021 Made by Windmill. All rights reserved.
//

import Foundation

private var _appGroupIdentifier: String?

public struct MBWConstants {
    public static var appGroupIdentifier: String {
        get {
            if _appGroupIdentifier == nil {
                _appGroupIdentifier = getAppGroupIdentifier()
            }
            return _appGroupIdentifier!
        }
    }

    private static func getAppGroupIdentifier() -> String {
        guard let infoDict = Bundle.main.infoDictionary else {
            fatalError("Couldn't read Info.plist")
        }
        if let str = infoDict["MBWAppGroupIdentifier"] as? String {
            return str
        } else {
            fatalError("MBWAppGroupIdentifier missing from target's Info.plist")
        }
    }
}
