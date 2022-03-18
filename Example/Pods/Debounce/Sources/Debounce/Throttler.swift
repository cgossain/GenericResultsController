//
//  Throttler.swift
//
//  Copyright (c) 2022 Christian Gossain
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/// Use a Throttler instance to implement debouncing.
///
/// This class was inspired by this blog post:
/// http://danielemargutti.com/2017/10/19/throttle-in-swift/
public final class Throttler {
    /// The label prefix used for internal dispatch queues.
    private static let queueLabelPrefix = "com.cgossain.debounce.throttler"

    /// The stable identity of the throttler instance.
    ///
    /// This identifier is used as part of the receivers' dispatch queue label.
    public let id: String
    
    /// Internal serial execution queue initialized with the specified QOS class.
    public let queue: DispatchQueue
    
    
    // MARK: - Private
    
    /// The internal lock queue.
    private let lockQueue = DispatchQueue(label: "\(Throttler.queueLabelPrefix).lock", attributes: .concurrent)
    
    /// The throttling interval.
    private var throttlingInterval: Double
    
    /// The maximum time interval to wait before throttling a block regadless of the throttling interval.
    ///
    /// Set to 0 to disable the max interval.
    private var maxInterval: Double
    
    /// The underlying storage for the last run timestamp.
    private var _lastRun = Date.timeIntervalSinceReferenceDate
    
    /// The underlying storage for the current work item.
    private var _currenWorkItem: DispatchWorkItem?
    
    /// Thread-safe read/write access to the last run timestamp.
    private var lastRun: TimeInterval {
        get {
            return lockQueue.sync {
                return _lastRun
            }
        }
        set {
            lockQueue.sync(flags: [.barrier]) {
                _lastRun = newValue
            }
        }
    }
    
    /// Thread-safe read/write access to the current work item.
    private var currenWorkItem: DispatchWorkItem? {
        get {
            return lockQueue.sync {
                return _currenWorkItem
            }
        }
        set {
            lockQueue.sync(flags: [.barrier]) {
                _currenWorkItem = newValue
            }
        }
    }
    
    
    // MARK: - Lifecycle
    
    /// Creates an returns a new throttler instance.
    ///
    /// - Parameters:
    ///     - id: A uniquie identifier for this instance.
    ///     - throttlingInterval: The time interval at which to throttle blocks.
    ///     - maxInterval: The maximum time interval to wait before throttling a block. Set to 0 to disable the max interval.
    public init(id: String = UUID().uuidString, throttlingInterval: Double, maxInterval: Double = 0, qosClass: DispatchQoS.QoSClass = .background) {
        self.id = id
        self.throttlingInterval = throttlingInterval
        self.maxInterval = maxInterval
        self.queue = DispatchQueue(label: "\(Throttler.queueLabelPrefix).\(id)", qos: DispatchQoS(qosClass: qosClass, relativePriority: 0), attributes: [])
    }
    
    public func throttle(fireNow: Bool = false, block: @escaping () -> ()) {
        currenWorkItem?.cancel()
        let workItem = DispatchWorkItem() { [weak self] in
            guard let strongSelf = self else { return }
            block()
            strongSelf.lastRun = Date.timeIntervalSinceReferenceDate
            
            // at this point the throttled work item has
            // completed, so we break any potential retain
            // cycles by clearing our reference to the it
            strongSelf.currenWorkItem = nil
        }
        currenWorkItem = workItem
        
        // throttle
        if fireNow {
            // enqueue for immediate execution
            queue.async(execute: workItem)
        }
        else if maxInterval == 0 {
            // enqueue for future execution
            queue.asyncAfter(deadline: .now() + throttlingInterval, execute: workItem)
        }
        else {
            let now = Date.timeIntervalSinceReferenceDate
            let timeIntervalSinceLastRun = now - lastRun
            
            // enqueue for future execution, but no later then the max interval
            if timeIntervalSinceLastRun > maxInterval {
                queue.async(execute: workItem)
            }
            else {
                queue.asyncAfter(deadline: .now() + throttlingInterval, execute: workItem)
            }
        }
    }
}
