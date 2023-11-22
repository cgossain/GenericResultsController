//
//  BatchQueue.swift
//
//  Copyright (c) 2023 Christian Gossain
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
import Debounce

/// The enqueue operation type.
public enum BatchQueueOperationType {
    /// The type if the object was
    /// newly inserted into the results set.
    case insert
    
    /// The type if the object was
    /// updated in the results set.
    case update
    
    /// The type if the object was
    /// deleted from the results set.
    case delete
}

/// A generic implementation of the batch queue delegate.
///
/// In order to support generics, this protocol is defined as a class object with closure parameters rather than an actual Swift protocol.
public final class BatchQueueDelegate<ResultType: DataStoreResult> {
    /// Called when the controller is about to begin collecting a new batch.
    public var queueWillBeginBatchingChanges: ((_ queue: BatchQueue<ResultType>) -> Void)?
    
    /// Called when the controller has finished processing a batch.
    public var queueDidFinishBatchingChanges: ((_ queue: BatchQueue<ResultType>, _ batch: Batch<ResultType>) -> Void)?
}

/// A queue that regulates the grouping of incremental changes into batch objects.
///
/// In some cases, you may want to process a batch immediatly (e.g. due to a user driven UI interaction), in this
/// case you can call the `processPendingChanges()` method.
///
/// If however you want the queue to always process changes immediatly, set
/// the `processesChangesImmediately` property to `true`.
public final class BatchQueue<ResultType: DataStoreResult> {
    /// Set to true if changes should not be batched but rather processed as soon as they are received.
    public var processesChangesImmediately = false
    
    /// The object that will receive batching updates. For internal use only.
    public var delegate = BatchQueueDelegate<ResultType>()
    
    /// Indicates if the receiver has an active batch.
    public var isBatching: Bool { return !batchByID.isEmpty }
    
    // MARK: - Init
    
    /// Creates and returns a new batch queue.
    public init() {
        
    }
    
    // MARK: - Private
    
    /// The currently active batches keyed by the fetch handle they're associated with.
    private var batchByID: [String : Batch<ResultType>] = [:]
    
    /// The throttler.
    private let throttler = Throttler(throttlingInterval: 0.3)
}

extension BatchQueue {
    /// Adds the given objects to the batch using the specified batch operation.
    ///
    /// - Parameters:
    ///     - results: The objects to enqueue into the batch.
    ///     - op: The type of enqueue operation.
    ///     - batchID: An identifier that associates enqueued changes with a particular batch.
    public func enqueue(_ results: [ResultType], as op: BatchQueueOperationType, batchID: String) {
        // notify the delegate if we're
        // about to start a new batch
        if !isBatching {
            delegate.queueWillBeginBatchingChanges?(self)
        }
        
        // get the batch associated with the
        // requested fetch handle
        let batch = batchByID[batchID] ?? Batch(id: batchID)
        batchByID[batchID] = batch
        
        // enqueue writes to the current batch
        switch op {
        case .insert:
            results.forEach { batch.insert($0) }
        case .update:
            results.forEach { batch.update($0) }
        case .delete:
            results.forEach { batch.delete($0) }
        }
        
        // throttle the flush
        throttler.throttle(fireNow: processesChangesImmediately) {
            DispatchQueue.main.async {
                self.flush(batchID: batchID)
            }
        }
    }
    
    /// Removes the batch matching the given ID.
    ///
    /// If there are no active batches matching the given ID, this method does nothing.
    public func dequeue(batchID: String) {
        batchByID[batchID] = nil
    }
    
    /// Forces the queue to flush the batch associated with the given batchID.
    ///
    /// By default, the queue automatically flushes enqueued changes when it reaches its throttling interval, this method flushes it explicitly.
    ///
    /// If there is no active batch for the given batchID, this method will still create an empty batch in order to trigger the delegate callback.
    ///
    /// - Note: This method is not useful if you've set `processesChangesImmediately` to `true`.
    public func processPendingChanges(batchID: String) {
        // create an empty batch so that the
        // flush call triggers the delegate
        if batchByID[batchID] == nil {
            batchByID[batchID] = Batch(id: batchID)
        }
        
        // throttle the flush
        throttler.throttle(fireNow: true) {
            DispatchQueue.main.async {
                self.flush(batchID: batchID)
            }
        }
    }
}

extension BatchQueue {
    /// Flushes the batch associated with the given batch ID and notifies the delegate.
    ///
    /// Calling this method terminates the batch for the specified ID, meaning any futher changes are tracked as part of a new batch.
    ///
    /// - Parameters:
    ///     - batchID: A batch identifier. This is used to track which batch objects are added to.
    ///
    /// - Important: This method is called from the throtter's queue.
    private func flush(batchID: String) {
        guard let batch = batchByID[batchID] else { return }
        
        // discarding the batch
        batchByID[batchID] = nil
        
        // send the batch to the delegate
        delegate.queueDidFinishBatchingChanges?(self, batch)
    }
}
