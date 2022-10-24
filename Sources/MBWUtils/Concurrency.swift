//
//  Concurrency.swift
//  
//  Created by John Scalo on 6/9/21.
//  Copyright © 2017-2022 Made by Windmill. All rights reserved.
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

/** ParallelAsync simplifies the queueing of concurrent operations. It has some advantages over common OperationQueue usage:

  * Its executeAndWait executes synchronously, which allows for local object retainment.
  * The completion always executes on the main thread.
  * It has a more concise syntax.

 ParallelAsync can work with a provided `OperationQueue` (which is handy if you want to set a concurrency limit), otherwise it uses `DispatchGroup`.
*/
public class ParallelAsync {
    
    private var parallelQ = DispatchQueue(label: "ParallelAsyncParallelQ", attributes: .concurrent)
    private var blocks = [(()->Void)]()
    private var opq: OperationQueue?
    
    /// Instantiate a ParallelAsync object. The provided `opq` will be used if provided, otherwise a DispatchGroup is used.
    public init(opq: OperationQueue? = nil) {
        self.opq = opq
    }
    
    public func add(_ block: @escaping (()->Void)) {
        blocks.append(block)
    }
    
    /// Execute all blocks, wait for their completion, and fire the completion block on the main thread when done.
    /// Since this is a synchronous function, do not call on the main thread from a UIKit/AppKit/SwiftUI app.
    public func executeAndWait(completion: @escaping (()->Void)) {
        if let opq = opq {
            _executeAndWaitWithOpQ(opq, completion: completion)
        } else {
            let group = DispatchGroup()
            _executeAndWaitWithGroup(group, completion: completion)
        }
    }
    
    private func _executeAndWaitWithGroup(_ group: DispatchGroup, completion: @escaping (()->Void)) {
        for nextBlock in blocks {
            group.enter()
            parallelQ.async {
                nextBlock()
                group.leave()
            }
        }
        group.wait()
        
        DispatchQueue.main.async {
            completion()
        }
    }
    
    private func _executeAndWaitWithOpQ(_ opq: OperationQueue, completion: @escaping (()->Void)) {
        for nextBlock in blocks {
            opq.addOperation(nextBlock)
        }
        opq.waitUntilAllOperationsAreFinished()
        
        DispatchQueue.main.async {
            completion()
        }
    }

}

public extension DispatchQueue {
    
    private static var _onceTracker = Set<String>()
    
    /// Execute a block of code exactly once per token.
    /// - Parameters:
    ///   - token: A unique token
    ///   - block: The block to be executed
    class func once(token: String, block:()->Void) {
        objc_sync_enter(self); defer { objc_sync_exit(self) }

        if _onceTracker.contains(token) {
            return
        }

        _onceTracker.insert(token)
        block()
    }
    
    /// Execute a block of code exactly once per object.
    /// - Parameters:
    ///   - sender: The object wishing to execute the block one time
    ///   - block: The block to be executed
    class func once(sender: AnyObject, file: String = #file, line: Int = #line, block:()->Void) {
        let token = addressString(of: sender) + file + "\(line)"
        DispatchQueue.once(token: token, block: block)
    }
}