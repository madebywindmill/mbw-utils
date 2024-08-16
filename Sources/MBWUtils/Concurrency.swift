//
//  Concurrency.swift
//  
//  Created by John Scalo on 6/9/21.
//  Copyright © 2017-2022 Made by Windmill. All rights reserved.
//

import Foundation

// MARK: - Utility Functions


public func mainAsync(_ block: @escaping @Sendable @MainActor () -> Void) {
    Task { @MainActor in
        block()
    }
}

public func mainAsyncAfter(_ interval: TimeInterval, _ block: @escaping @Sendable @MainActor () -> Void) {
    Task { @MainActor in
        let nanoseconds = UInt64(interval * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
        block()
    }
}

public func globalAsync(_ block: @escaping @Sendable () -> Void) {
    Task.detached {
        block()
    }
}

public func globalAsyncAfter(_ interval: TimeInterval, _ block: @escaping @Sendable () -> Void) {
    Task.detached {
        let nanoseconds = UInt64(interval * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoseconds)
        block()
    }
}

// MARK: - ParallelAsync

/** ParallelAsync simplifies the queueing of concurrent operations. It has some advantages over common OperationQueue usage:

  * Its executeAndWait executes synchronously, which allows for local object retainment.
  * The completion always executes on the main thread.
  * It has a more concise syntax.
*/
public final class ParallelAsync: @unchecked Sendable {
    private var blocks = [@Sendable () async -> Void]()
    
    public init() {}

    /// Add an async block of work to be executed in parallel.
    public func add(_ block: @escaping @Sendable () async -> Void) {
        blocks.append(block)
    }
    
    /// Execute all blocks concurrently, wait for their completion, and fire the completion block on the main thread when done.
    /// Since this is a synchronous function, do not call on the main thread from a UIKit/AppKit/SwiftUI app.
    public func executeAndWait(completion: @escaping @Sendable () -> Void) {
        let localBlocks = blocks
        
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.global(qos: .userInitiated).async {
            Task {
                await withTaskGroup(of: Void.self) { taskGroup in
                    for block in localBlocks {
                        taskGroup.addTask {
                            await block()
                        }
                    }
                }

                semaphore.signal()

                await MainActor.run {
                    completion()
                }
            }
        }
        
        semaphore.wait()
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

// See http://www.russbishop.net/the-law
public class UnfairLock {
    private var _lock: UnsafeMutablePointer<os_unfair_lock>

    public init() {
        _lock = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        _lock.initialize(to: os_unfair_lock())
    }

    deinit {
        _lock.deallocate()
    }

    public func locked<ReturnValue>(_ f: () throws -> ReturnValue) rethrows -> ReturnValue {
        os_unfair_lock_lock(_lock)
        defer { os_unfair_lock_unlock(_lock) }
        return try f()
    }
}

@available(iOS 13, macOS 12.0, watchOS 6, *)
public extension Sequence {
    func parallelForEach(_ block: @escaping @Sendable (Element) async throws -> ()) async rethrows {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    try await block(element)
                }
            }
            
            try await group.waitForAll()
        }
    }
    
    func parallelForEach(maxTaskCnt: Int, _ block: @escaping @Sendable (Element) async throws -> ()) async rethrows {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (idx, element) in self.enumerated() {
                if idx >= maxTaskCnt {
                    try await group.next()
                }
                group.addTask {
                    try await block(element)
                }
            }
            
            try await group.waitForAll()
        }
    }
}

/// This is handy for creating concurrency-safe local arrays and dictionaries, for which it can be used to store either or both. Replaces deprecated `IsolatedCollectionStore` and `MainActorIsolatedCollectionStore`.
public class LockingCollectionStore: @unchecked Sendable  {
    private let lock = NSLock()

    private var _a: [Any] = []
    private var _d: [AnyHashable: Any] = [:]

    public var a: [Any] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _a
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _a = newValue
        }
    }

    public var d: [AnyHashable: Any] {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _d
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _d = newValue
        }
    }

    public init() {}
    
    public func append(_ e: Any) {
        lock.lock()
        defer { lock.unlock() }
        _a.append(e)
    }

    public func set(value: Any, key: AnyHashable) {
        lock.lock()
        defer { lock.unlock() }
        _d[key] = value
    }

    public subscript(key: AnyHashable) -> Any? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _d[key]
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _d[key] = newValue
        }
    }
}

/// Doesn't work well with Swift 6, so deprecated in favor of `LockingCollectionStore`.
@available(iOS 13, macOS 12.0, watchOS 6, *)
@available(*, deprecated, message: "Use LockingCollectionStore instead.")
public actor IsolatedCollectionStore {
    public var a = [Any]()
    public var d = [AnyHashable:Any]()
    
    public init() {}
    
    public func append(_ e: Any) {
        a.append(e)
    }
    
    public func set(value: Any, key: AnyHashable) {
        d[key] = value
    }
    
    public subscript(key: AnyHashable) -> Any? {
        get {
            return d[key]
        }
        set {
            d[key] = newValue
        }
    }

}

/// Doesn't work well with Swift 6, so deprecated in favor of `LockingCollectionStore`.
@available(*, deprecated, message: "Use LockingCollectionStore instead.")
@MainActor public class MainActorIsolatedCollectionStore {
    public var a = [Any]()
    public var d = [AnyHashable:Any]()
    
    public init() {}
    
    public func append(_ e: Any) {
        a.append(e)
    }
    
    public func set(value: Any, key: AnyHashable) {
        d[key] = value
    }
    
    public subscript(key: AnyHashable) -> Any? {
        get {
            return d[key]
        }
        set {
            d[key] = newValue
        }
    }

}
