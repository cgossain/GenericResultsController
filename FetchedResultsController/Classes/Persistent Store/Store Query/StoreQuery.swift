//
//  StoreQuery.swift
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

extension StoreQuery: Identifiable {}

/// A long-running query that monitors the store and updates your results whenever matching objects are added, updated, or deleted.
public class StoreQuery<ResultType: StoreResult, RequestType: StoreRequest> {
    /// The search criteria used to retrieve data from a persistent store.
    public let storeRequest: RequestType
    
    /// Indicates if changes should always be processed as soon as they're enqueued.
    ///
    /// Alternatively, if you only want to process changes in some cases (i.e. due to user initiated action) you
    /// can call `processPendingChanges()`.
    public var processesChangesImmediately: Bool {
        get {
            return queue.processesChangesImmediately
        }
        set {
            queue.processesChangesImmediately = newValue
        }
    }
    
    /// A block that is called when a matching results are inserted, updated, or deleted from the store.
    public let updateHandler: (_ inserted: [ResultType]?, _ updated: [ResultType]?, _ deleted: [ResultType]?, _ error: Error?) -> Void
    
    
    // MARK: - Internal Properties
    
    /// The batch queue.
    private let queue = BatchQueue<ResultType>()
    
    
    // MARK: - Lifecycle
    
    /// Instantiates and returns a query.
    public init(storeRequest: RequestType, updateHandler: @escaping (_ inserted: [ResultType]?, _ updated: [ResultType]?, _ deleted: [ResultType]?, _ error: Error?) -> Void) {
        self.storeRequest = storeRequest
        self.updateHandler = updateHandler
        self.queue.delegate.queueDidFinishBatchingChanges = { [unowned self] (queue, batch) in
            let digest = batch.flush()
            self.updateHandler(digest.inserted, digest.updated, digest.deleted, nil)
        }
    }
    
    deinit {
        queue.dequeue(batchID: self.id)
    }
    
}

extension StoreQuery {
    // MARK: -  Resolving Observer Query
    
    /// Proceses all enqueued changes immediately.
    ///
    /// You should use this method if you've enqueued changes driven by user action (e.g. user deleted an item).
    ///
    /// - Note: In the event there are no results for the query, you can still use this method to trigger the update handler; it'll just report zero changes.
    public func processPendingChanges() {
        queue.processPendingChanges(batchID: self.id)
    }
        
    /// Enqueues the object as an insertion.
    public func enqueue(inserted: ResultType) {
        queue.enqueue(inserted,
                      as: .insert,
                      batchID: self.id)
    }

    /// Enqueues the object as an update.
    public func enqueue(updated: ResultType) {
        queue.enqueue(updated,
                      as: .update,
                      batchID: self.id)
    }
    
    /// Enqueues the object as an deletion.
    public func enqueue(deleted: ResultType) {
        queue.enqueue(deleted,
                      as: .delete,
                      batchID: self.id)
    }
}
