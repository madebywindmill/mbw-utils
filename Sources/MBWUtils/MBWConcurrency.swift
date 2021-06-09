//
//  MBWConcurrency.swift
//  
//  Created by John Scalo on 6/9/21.
//  Copyright © 2017-2021 Made by Windmill. All rights reserved.
//

import Foundation

public func mainAsync(_ block: @escaping (()->())) {
    DispatchQueue.main.async {
        block()
    }
}

public func mainAsyncAfter(_ interval: TimeInterval, _ block: @escaping (()->())) {
    DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: block)
}

public func globalAsync(_ block: @escaping (()->())) {
    DispatchQueue.global().async {
        block()
    }
}

public func globalAsyncAfter(_ interval: TimeInterval, _ block: @escaping (()->())) {
    DispatchQueue.global().asyncAfter(deadline: .now() + interval, execute: block)
}
