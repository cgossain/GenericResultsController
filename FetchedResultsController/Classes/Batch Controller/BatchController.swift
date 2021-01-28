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

final class BatchControllerDelegate<ResultType: BaseResultObject> {
    /// Called when the controller is about to begin collecting a new batch.
    var controllerWillBeginBatchingChanges: ((_ controller: BatchController<ResultType>) -> Void)?
    
    /// Called when the controller has finished processing a batch.
    var controllerDidFinishBatchingChanges: ((_ controller: BatchController<ResultType>, _ inserted: Set<ResultType>, _ updated: Set<ResultType>, _ deleted: Set<ResultType>) -> Void)?
}

/// A controller object used to group incoming changes into a single batch of changes.
///
/// Using an internal throttler, the batch controller resets a timer (currently 0.3 seconds) each time a new change is added to the batch. In some cases you
/// may want to process a batch immediatly, in this case you can call the `processBatch()` method. If the controller should always process changes
/// immediatly, simply set the `processesChangesImmediately` property to `true`.
final class BatchController<ResultType: BaseResultObject>: Identifiable {
    /// The stable identity of the batch controller instance.
    var id: String { return throttler.id }
    
    /// The current fetch handle.
    ///
    /// - Note: This is automatically incremented by the store connector whenever `execute(_:)` is called.
    var currentFetchHandle = 0
    
    /// Set to true if changes should not be batched but rather processed as soon as they are received.
    var processesChangesImmediately = false
    
    /// The object that will receive batching updates. For internal use only.
    var delegate = BatchControllerDelegate<ResultType>()
    
    /// Indicates if the controller is currently batching.
    private(set) var isBatching = false
    
    
    // MARK: - Private Properties
    
    /// The throttler.
    private let throttler = Throttler(throttlingInterval: 0.3)
    
    /// The currently active batches keyed by the fetch handle they're associated with.
    private var batchByFetchHandle: [Int : Batch<ResultType>] = [:]
    
}

extension BatchController {
    enum OperationType {
        case insert
        case update
        case delete
    }
    
    /// Adds the given object to the batch using the specified batch operation.
    func enqueue(_ obj: ResultType, as op: OperationType, fetchHandle: Int = 0) {
        // enqueue writes to the batch onto the throttlers serial queue
        throttler.queue.async {
            self.notifyWillBeginBatchingIfNeeded()
        }
        
        // get the batch associated with the requested fetch handle
        let batch = batchByFetchHandle[fetchHandle] ?? Batch()
        batchByFetchHandle[fetchHandle] = batch
        
        // enqueue writes to the batch onto the throttlers serial queue
        switch op {
        case .insert:
            throttler.queue.async {
                batch.insert(obj)
            }
        case .update:
            throttler.queue.async {
                batch.update(obj)
            }
        case .delete:
            throttler.queue.async {
                batch.delete(obj)
            }
        }
        
        // throttle the flush; the throttler uses a serial execution queue so while chunks of work keep getting
        // enqueue above, this chunk of work effectively will keep moving to the end of the execution queue until
        // no more writes are enqueued for the throttling interval
        throttler.throttle(fireNow: processesChangesImmediately) {
            self.flush()
        }
    }
    
    /// By default, the batch controller flushes enqueued changes when it reaches its throttling interval. This method flushes it explicitly.
    ///
    /// - Note: This method is not useful if you've already set `processesChangesImmediately` to `true`.
    func processPendingChanges() {
        throttler.throttle(fireNow: true) {
            self.flush()
        }
    }
}

extension BatchController {
    /// Internal method that calls `controllerWillBeginBatchingChanges` if the controller is not currently batching. Otherwise does nothing.
    private func notifyWillBeginBatchingIfNeeded() {
        if !isBatching {
            isBatching = true
            
            // notify the delegate
            DispatchQueue.main.async {
                self.delegate.controllerWillBeginBatchingChanges?(self)
            }
        }
    }
    
    /// Flushes the batch associated with the current fetch handle to the delegate.
    ///
    /// Calling this method terminates the batch meaning any futher changes will now become part of a new batch.
    ///
    /// Any batches associated with older fetch handles are discarded.
    ///
    /// - Important: This method is called from the throtter's queue.
    private func flush() {
        if let batch = batchByFetchHandle[currentFetchHandle] {
            // flush the batch
            let results = batch.flush()
            
            // finish the batch
            isBatching = false
            
            // notify the delegate
            DispatchQueue.main.async {
                self.delegate.controllerDidFinishBatchingChanges?(self, Set(results.inserted.values), Set(results.updated.values), Set(results.deleted.values))
            }
        }
        else {
            // notify the delegate
            DispatchQueue.main.async {
                self.delegate.controllerDidFinishBatchingChanges?(self, [], [], [])
            }
        }
        
        // clear the reference to all tracked batches
        batchByFetchHandle.removeAll()
    }
}
