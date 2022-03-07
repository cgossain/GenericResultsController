//
//  DataStoreQuery.swift
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

/// A query that returns resuls of a fetch executed against a data store instance.
///
/// This query can be used as a long-running query or can be short-lived; the difference comes
/// down to how you implement it.
///
/// For a long-running query, setup database observers in your data store implementation
/// and continually enqueue changes whenever objects matching the search criteria (defined
/// by `request`) are added, updated, or deleted from the data store.
///
/// For a short-lived query, you don't setup any observers, just perform the fetch and enqueue
/// the results once (e.g. an API fetch, or a simple database query).
public final class DataStoreQuery<ResultType: DataStoreResult, RequestType: DataStoreRequest>: InstanceIdentifiable {
    /// The sucessful result type.
    public typealias Success = (inserted: [ResultType]?, updated: [ResultType]?, deleted: [ResultType]?)
    
    /// The update handler signature.
    public typealias UpdateHandler = (_ result: Swift.Result<Success, Swift.Error>) -> Void
    
    /// The search criteria used to retrieve data from a persistent store.
    public let request: RequestType
    
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
    public let updateHandler: UpdateHandler
    
    
    // MARK: - InstanceIdentifiable
    
    /// The stable identity of the entity associated with this instance.
    public var id = UUID().uuidString
    
    
    // MARK: - Internal Properties
    
    /// The batch queue.
    private let queue = BatchQueue<ResultType>()
    
    
    // MARK: - Lifecycle
    
    /// Creates and returns a new store query.
    ///
    /// - Parameters:
    ///     - request: The criteria used to retrieve data from a persistent store.
    ///     - processesChangesImmediately: Indicates if changes should always be processed as soon as they're enqueued.
    ///     - updateHandler: A block that is called when a matching results are inserted, updated, or deleted from the store.
    public init(
        request: RequestType,
        processesChangesImmediately: Bool = false,
        updateHandler: @escaping UpdateHandler
    ) {
        self.request = request
        self.updateHandler = updateHandler
        self.queue.processesChangesImmediately = processesChangesImmediately
        self.queue.delegate.queueDidFinishBatchingChanges = { [unowned self] (queue, batch) in
            let digest = batch.flush()
            let success = (digest.inserted, digest.updated, digest.deleted)
            self.updateHandler(.success(success))
        }
    }
    
    deinit {
        queue.dequeue(batchID: self.id)
    }
    
}

extension DataStoreQuery {
    // MARK: -  Resolving Observer Query
    
    /// Adds the given objects to the query using the given operation type.
    public func enqueue(_ results: [ResultType], as op: BatchQueueOperationType) {
        queue.enqueue(results, as: op, batchID: self.id)
    }
    
    /// Proceses all enqueued changes immediately.
    ///
    /// You should use this method if you've enqueued changes driven by user action (e.g. user deleted an item).
    ///
    /// - Note: In the event there are no results for the query, you can still use this method to trigger the update handler; it'll just report zero changes.
    public func processPendingChanges() {
        queue.processPendingChanges(batchID: self.id)
    }
    
    /// Rejects the query with the given error.
    ///
    /// This will trigger the update handler with a result of `failure`.
    public func reject(_ error: Error) {
        // leaving as a thought:
        //
        // would it make more sense to wrap this
        // into a Promise? idea being that
        // we should only be able to reject a
        // query once; if a query has been rejected
        // should it still receive further updates?
        updateHandler(.failure(error))
    }
}
