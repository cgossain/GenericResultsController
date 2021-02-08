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
/// fetched results controller and any data store. It's a stateless adapter to some database.
///
/// The API is intentionally simple and makes no assumptions about how you manage your connection to the
/// underlying data store. Your concrete subclass should implement any state and logic needed to communicate
/// with your underlying store (i.e. opening connections, attaching observers, closing connections, cleaning up).
///
/// The abstract connector uses a batching mechanism internally to efficiently compute diffs in batches, however
/// this can be bypassed if you want changes to be processed immediately (especially if the change is user initiated).
///
/// Your concrete subclass should use the defined enqueuing methods to notify the connector of the results of a
/// query or any subsequent changes (if observers were attached).
open class StoreConnector<ResultType: FetchRequestResult, RequestType: FetchRequest<ResultType>>: NSObject {
    /// A short decriptive title for the data store.
    public let title: String
    
    /// Indicates if changes should always be processed as soon as they're enqueued.
    ///
    /// Alternatively, if you only want to process changes in some cases (i.e. due to user initiated action) you
    /// can call `processPendingChanges()`.
    public var processesChangesImmediately: Bool {
        get {
            return batchController.processesChangesImmediately
        }
        set {
            batchController.processesChangesImmediately = newValue
        }
    }
    
    /// Th fetch handle associated with the most recent call to `execute(_:)`.
    ///
    /// This value is incremented everytime `performFetch(_:)` is called.
    public private(set) var currentFetchHandle: Int = 0 {
        didSet {
            // the store connector act as the "source of truth" for the
            // fetch handle, so we just pass it on down to the batch controller
            // whenever it changes here
            batchController.currentFetchHandle = currentFetchHandle
        }
    }
    
    
    // MARK: -  Internal
    
    /// The controller used to batch incoming changes from the data store.
    let batchController = BatchController<ResultType>()
    
    
    // MARK: -  Lifecycle
    
    /// Initializes a new store connector instance.
    public init(title: String = "") {
        self.title = title
    }
    
    /// Proceses all enqueued changes immediately.
    ///
    /// You should use this method if you've enqueued changes driven by user action (e.g. user deleted an item).
    open func processPendingChanges() {
        batchController.processPendingChanges()
    }
    
    /// Executes the given store request.
    ///
    /// You must subclass this method and implement your own fetching logic.
    ///
    /// A simple way to impmement this method is to fetch the data (according to the constraints of the given store request) and
    /// return the results with no further action. This assumes you've built some kind of pull to refresh mechanism and will call the
    /// result controllers' `performFetch(_:)` method everytime to trigger a new fetch.
    ///
    /// A more advanced wat to implement this method would be to attach long running observers that observe the database
    /// for changes (according to the constraints of the given store request) and then to return the results everytime an observer
    /// notifies you of a change. With this kind of implementation, the fetch essentially becomes long running and enables
    /// results to be "live updated" without user intervention.
    ///
    /// The above a just two examples, but there are surely myriad ways of implementing this method. Regardless of how you
    /// implement this method, you notify the store connector of any results or changes to the data associated with the store request
    /// by calling one of the appropriate `enqueue` methods.
    ///
    /// - Parameters:
    ///     - request: The store request.
    ///
    /// - Important: Call `super.execute(_:)` as the first step in your implementation.
    open func execute(_ request: RequestType) {
        // increment the fetch handle
        currentFetchHandle += 1
    }
    
    
    // MARK: -  Incremental Operations
    
    /// Enqueues the object as an insertion.
    open func enqueue(inserted: ResultType) {
        batchController.enqueue(inserted, as: .insert, fetchHandle: currentFetchHandle)
    }

    /// Enqueues the object as an update.
    open func enqueue(updated: ResultType) {
        batchController.enqueue(updated, as: .update, fetchHandle: currentFetchHandle)
    }
    
    /// Enqueues the object as an deletion.
    open func enqueue(removed: ResultType) {
        batchController.enqueue(removed, as: .delete, fetchHandle: currentFetchHandle)
    }
    
}
