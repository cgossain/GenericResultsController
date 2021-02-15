//
//  StoreConnector.swift
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

/// StoreConnector is an abstract superclass exposing a simple API for interfacing between a
/// fetched results controller and any data store. It's an adapter to some underlying store.
///
/// The API is intentionally simple and makes no assumptions about how you manage your connection
/// to the underlying data store. Your concrete subclass should implement any state and logic needed to
/// efficiently communicate with your underlying store (i.e. opening connections, attaching observers, closing
/// connections, cleaning up, caching objects, etc.).
///
/// Results are delivered to the observer query via a batching mechanism to optimize diffs by computing the
/// diffs agains the incremental changes rather then the full data set.
///
/// You call any of the `enqueue(_:_:)` methods to deliver result objects. If your fetch is short lived then you
/// would provide all your result objects using the "insertion" variant. Otherwise if you have long running observers
/// you can keep delivering incremental updates using all the variants.
open class StoreConnector<RequestType: FetchRequest> {
    /// A short descriptive title for the data store.
    public let title: String
    
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
    
    /// The currently running queries.
    public private(set) var queryByID: [AnyHashable : ObserverQuery<RequestType>] = [:]
    
    
    // MARK: - Private Properties
    
    /// The batch queue.
    private let queue = BatchQueue<RequestType.ResultType>()
    
    
    // MARK: -  Lifecycle
    
    /// Initializes a new store connector instance.
    public init(title: String = "") {
        self.title = title
        self.queue.delegate.queueDidFinishBatchingChanges = { [unowned self] queue, batch in
            let request = queryByID[batch.id]
            request?.updateHandler(batch.flush())
        }
    }
    
    /// Executes the given query.
    ///
    /// You need to override this method and implement your own fetching logic.
    ///
    /// The simplest way to impmement this method is to fetch the requested data (within the constraints of the specified fetch
    /// request) and return the results with no further action. This assumes you have some mechanism that automatically calls
    /// the result controllers' `performFetch(_:)` method to trigger a new fetch (e.g. pull to refresh, load on view will appear, etc.).
    ///
    /// A more advanced way to implement this method might be to attach long running observers that observe the database
    /// for changes (within the constraints of the specified fetch request) and then returns a batch of incremental results everytime
    /// an observer notifies you of a change. In other words this would be a way to deliver "live updates" to the UI.
    ///
    /// The above are just two examples, but there could be myriad ways of implementing this method.
    ///
    /// - Parameters:
    ///     - query: The query.
    ///
    /// - Important: Call `super.execute(_:)` as the first step in your implementation.
    open func execute(_ query: ObserverQuery<RequestType>) {
        queryByID[query.id] = query
    }
    
    /// Stops the receiver from gathering further results for the given query.
    ///
    /// You need to override this method to perform any cleanup relating to stopping the query (e.g. removing database listeners).
    ///
    /// - Note: If the query is not running, this method does nothing.
    open func stop(_ query: ObserverQuery<RequestType>) {
        queryByID[query.id] = nil
        queue.dequeue(batchID: query.id)
    }
    
    /// Proceses all enqueued changes immediately.
    ///
    /// You should use this method if you've enqueued changes driven by user action (e.g. user deleted an item).
    open func processPendingChanges(for query: ObserverQuery<RequestType>) {
        queue.processPendingChanges(batchID: query.id)
    }
    
    
    // MARK: -  Incremental Results
        
    /// Enqueues the object as an insertion.
    open func enqueue(inserted: RequestType.ResultType, for query: ObserverQuery<RequestType>) {
        queue.enqueue(inserted, as: .insert, batchID: query.id)
    }

    /// Enqueues the object as an update.
    open func enqueue(updated: RequestType.ResultType, for query: ObserverQuery<RequestType>) {
        queue.enqueue(updated, as: .update, batchID: query.id)
    }
    
    /// Enqueues the object as an deletion.
    open func enqueue(deleted: RequestType.ResultType, for query: ObserverQuery<RequestType>) {
        queue.enqueue(deleted, as: .delete, batchID: query.id)
    }
}

extension StoreConnector: Identifiable, Equatable {
    public static func == (lhs: StoreConnector<RequestType>, rhs: StoreConnector<RequestType>) -> Bool {
        return lhs.id == rhs.id
    }
}
