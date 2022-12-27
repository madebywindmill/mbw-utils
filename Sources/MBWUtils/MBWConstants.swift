//
//  MBWConstants.swift
//
//  Created by John Scalo on 1/5/21.
//  Copyright © 2022 Made by Windmill. All rights reserved.
//

import Foundation

private var _appGroupIdentifier: String?
private var _hasAttemptedAppGroupID = false

public struct MBWConstants {
    public static var appGroupIdentifier: String? {
        get {
            if _appGroupIdentifier == nil && !_hasAttemptedAppGroupID {
                _appGroupIdentifier = getAppGroupIdentifier()
            }
            return _appGroupIdentifier!
        }
    }

    private static func getAppGroupIdentifier() -> String? {
        _hasAttemptedAppGroupID = true
        
        guard let infoDict = Bundle.main.infoDictionary else {
            print("*** Couldn't read Info.plist")
            return nil
        }
        if let str = infoDict["MBWAppGroupIdentifier"] as? String {
            return str
        } else {
            print("*** MBWAppGroupIdentifier missing from target's Info.plist.")
            return nil
        }
    }
}
