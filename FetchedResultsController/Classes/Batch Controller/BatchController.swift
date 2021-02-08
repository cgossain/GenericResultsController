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

final class BatchControllerDelegate<ResultType: FetchRequestResult> {
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
final class BatchController<ResultType: FetchRequestResult>: Identifiable {
    /// The stable identity of the batch controller instance.
    var id: String { return throttler.id }
    
    /// Set to true if changes should not be batched but rather processed as soon as they are received.
    var processesChangesImmediately = false
    
    /// The object that will receive batching updates. For internal use only.
    var delegate = BatchControllerDelegate<ResultType>()
    
    /// The current fetch handle.
    ///
    /// - Note: This is automatically incremented by the store connector whenever `execute(_:)` is called.
    var currentFetchHandle = 0
    
    /// Indicates if the receiver has an active batch.
    var isBatching: Bool { return batchByFetchHandle[currentFetchHandle] != nil }
    
    
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
        // notify the delegate if we're about to start a new batch
        if !isBatching {
            delegate.controllerWillBeginBatchingChanges?(self)
        }
        
        // get the batch associated with the requested fetch handle
        let batch = batchByFetchHandle[fetchHandle] ?? Batch()
        batchByFetchHandle[fetchHandle] = batch
        
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
                self.flush()
            }
        }
    }
    
    /// By default, the batch controller flushes enqueued changes when it reaches its throttling interval. This method flushes it explicitly.
    ///
    /// - Note: This method is not useful if you've already set `processesChangesImmediately` to `true`.
    func processPendingChanges() {
        throttler.throttle(fireNow: true) {
            DispatchQueue.main.async {
                self.flush()
            }
        }
    }
}

extension BatchController {
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
            
            // discarding the processed the batch
            batchByFetchHandle[currentFetchHandle] = nil
            
            // notify the delegate
            delegate.controllerDidFinishBatchingChanges?(self, Set(results.inserted.values), Set(results.updated.values), Set(results.deleted.values))
        }
        else {
            // notify the delegate
            delegate.controllerDidFinishBatchingChanges?(self, [], [], [])
        }
        
        // cleanup by discarding any other batches; this might
        // happen if a call to `performFetch()` was made while
        // there was an active batch in process which in turn would have
        // caused the `currentFetchHandle` to be incremented; note this
        // mechanism is by design in order to invalidate results
        // between calls to `performFetch()`
        batchByFetchHandle.removeAll()
    }
}
