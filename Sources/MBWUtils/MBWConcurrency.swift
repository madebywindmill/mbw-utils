//
//  MBWConcurrency.swift
//  
//  Created by John Scalo on 6/9/21.
//  Copyright © 2017-2021 Made by Windmill. All rights reserved.
//

import Foundation

// MARK: - Utility Functions

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

// MARK: - ParallelAsync

//  ParallelAsync behaves a lot like an OperationQueue + dependencies with the following exceptions:
//
//  * It always executes synchronously, which allows for local object retainment.
//  * The completion always executes on the main thread.
//  * It has a more concise syntax.
//

public class ParallelAsync {
    private var serialQ = DispatchQueue(label: "ParallelAsyncSerialQ")
    private var group = DispatchGroup()
    private var blocks = [(()->Void)]()
    
    public func add(_ block: @escaping (()->Void)) {
        blocks.append(block)
    }
    
    public func executeAndWait(completion: @escaping (()->Void)) {
        for nextBlock in blocks {
            serialQ.async(group: group) {
                nextBlock()
            }
        }
        group.wait()
        
        DispatchQueue.main.async {
            completion()
        }
    }
}
