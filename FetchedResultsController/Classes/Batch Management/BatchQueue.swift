//
//  BatchController.swift
//
//  Copyright (c) 2021 Christian Gossain
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

public final class BatchQueueDelegate<ResultType: StoreResult> {
    /// Called when the controller is about to begin collecting a new batch.
    public var queueWillBeginBatchingChanges: ((_ queue: BatchQueue<ResultType>) -> Void)?
    
    /// Called when the controller has finished processing a batch.
    public var queueDidFinishBatchingChanges: ((_ queue: BatchQueue<ResultType>, _ batch: Batch<ResultType>) -> Void)?
}

/// A queue that regulates the grouping of incremental changes in batches.
///
/// In some cases you may want to process a batch immediatly (e.g. due to a user driven UI interaction), in this
/// case you can call the `processPendingChanges()` method. If the queue should always process changes
/// immediatly, set the `processesChangesImmediately` property to `true`.
public final class BatchQueue<ResultType: StoreResult>: Identifiable {
    /// Set to true if changes should not be batched but rather processed as soon as they are received.
    public var processesChangesImmediately = false
    
    /// The object that will receive batching updates. For internal use only.
    public var delegate = BatchQueueDelegate<ResultType>()
    
    /// Indicates if the receiver has an active batch.
    public var isBatching: Bool { return !batchByID.isEmpty }
    
    
    // MARK: - Private Properties
    
    /// The currently active batches keyed by the fetch handle they're associated with.
    private var batchByID: [AnyHashable : Batch<ResultType>] = [:]
    
    /// The throttler.
    private let throttler = Throttler(throttlingInterval: 0.3)
    
    
    // MARK: - Lifecycle
    
    public init() {
        
    }
    
}

extension BatchQueue {
    public enum OperationType {
        case insert
        case update
        case delete
    }
    
    /// Adds the given object to the batch using the specified batch operation.
    ///
    /// - Parameters:
    ///     - obj: The object to enqueue into the batch.
    ///     - op: The type of enqueue operation.
    ///     - batchID: An identifier that associates enqueued changes with a particular batch.
    public func enqueue(_ obj: ResultType, as op: OperationType, batchID: AnyHashable) {
        // notify the delegate if we're about to start a new batch
        if !isBatching {
            delegate.queueWillBeginBatchingChanges?(self)
        }
        
        // get the batch associated with the requested fetch handle
        let batch = batchByID[batchID] ?? Batch(id: batchID)
        batchByID[batchID] = batch
        
        // enqueue writes to the current batch
        switch op {
        case .insert:
            batch.insert(obj)
        case .update:
            batch.update(obj)
        case .delete:
            batch.delete(obj)
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
    public func dequeue(batchID: AnyHashable) {
        batchByID[batchID] = nil
    }
    
    /// By default, the batch controller flushes enqueued changes when it reaches its throttling interval. This method flushes it explicitly.
    ///
    /// - Note: This method is not useful if you've already set `processesChangesImmediately` to `true`.
    public func processPendingChanges(batchID: AnyHashable) {
        // create an empty batch so that the flush call triggers the delegate
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
    private func flush(batchID: AnyHashable) {
        guard let batch = batchByID[batchID] else { return }
        
        // discarding the batch
        batchByID[batchID] = nil
        
        // send the batch to the delegate
        delegate.queueDidFinishBatchingChanges?(self, batch)
    }
}
