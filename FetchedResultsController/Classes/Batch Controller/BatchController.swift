//
//  BatchController.swift
//
//  Copyright (c) 2017-2020 Christian Gossain
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

enum BatchOperation {
    case insert
    case update
    case remove
}

final class BatchControllerDelegate<ResultType: FetchedResultsStoreRequest.Result> {
    /// Called when the controller is about to begin collecting a new batch.
    var controllerWillBeginBatchingChanges: ((_ controller: BatchController<ResultType>) -> Void)?
    
    /// Called when the controller has finished processing a batch.
    var controllerDidFinishBatchingChanges: ((_ controller: BatchController<ResultType>, _ inserted: Set<ResultType>, _ changed: Set<ResultType>, _ removed: Set<ResultType>) -> Void)?
}

/// A controller object used to group incoming changes into a single batch of changes.
///
/// Using an internal throttler, the batch controller resets a timer (currently 0.3 seconds) each time a new change is added to the batch. In some cases you
/// may want to process a batch immediatly, in this case you can call the `processBatch()` method. If the controller should always process changes
/// immediatly, simply set the `processesChangesImmediately` property to `true`.
final class BatchController<ResultType: FetchedResultsStoreRequest.Result> {
    /// A unique identifier for the batch controller.
    public var identifier: String { return throttler.identifier }
    
    /// The object that will receive batching updates.
    var delegate = BatchControllerDelegate<ResultType>()
    
    /// Set to true if changes should no be batched, but rather processed as soon as they are received.
    var processesChangesImmediately = false
    
    /// Indicates if the controller is currently batching.
    private(set) var isBatching = false
    
    
    // MARK: - Private Properties
    /// Returns the current batch being managed by the receiver.
    private var batch: Batch<ResultType> {
        // return the existing batch
        if let existingBatch = _batch {
            return existingBatch
        }
        
        // otherwise, create a new batch
        let newBatch = Batch<ResultType>()
        _batch = newBatch
        return newBatch
    }
    
    /// The backing ivar for the current batch.
    private var _batch: Batch<ResultType>?
    
    /// The internal throttler.
    private let throttler = Throttler(throttlingInterval: 0.3)
}

extension BatchController {
    /// Adds the given object to the batch using the specified batch operation.
    func enqueue(_ obj: ResultType, as op: BatchOperation) {
        // enqueue writes to the batch onto the throttlers serial queue
        throttler.queue.async {
            self.notifyWillBeginBatchingIfNeeded()
        }
        
        // enqueue writes to the batch onto the throttlers serial queue
        switch op {
        case .insert:
            throttler.queue.async {
                self.batch.insert(obj)
            }
        case .update:
            throttler.queue.async {
                self.batch.update(obj)
            }
        case .remove:
            throttler.queue.async {
                self.batch.remove(obj)
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
    
    /// Terminates any further tracking into the current batch and flushes the results to the delegate.
    private func flush() {
        if let batch = _batch {
            // flush the batch
            let results = batch.flush()
            
            // clear the reference to the current batch
            _batch = nil
            
            // finish the batch
            isBatching = false
            
            // notify the delegate
            DispatchQueue.main.async {
                self.delegate.controllerDidFinishBatchingChanges?(self, Set(results.inserted.values), Set(results.changed.values), Set(results.removed.values))
            }
        }
        else {
            // notify the delegate
            DispatchQueue.main.async {
                self.delegate.controllerDidFinishBatchingChanges?(self, [], [], [])
            }
        }
    }
}
