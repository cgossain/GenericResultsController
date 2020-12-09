//
//  FetchedResultsStoreConnector.swift
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

/// FetchedResultsStoreConnector is an abstract superclass defining a simple API to communicate with between an instance of
/// fetched results controller and any data store. This superclass is intended to be a stateless adapter to some database.
///
/// The API is intentionally simple, and it makes no assumptions about how you manage your connection to some
/// underlying data store. The only responsibility of the abstract store connector is to act as a throttling adapter between
/// your data store and the fetched results controller.
///
/// Your concrete subclass should implement any state and logic related to communicating with your underlying
/// store (i.e. opening connections, attaching observers, closing connections, cleaning up) and should manage enqueuing
/// changes detected by observers.
///
/// Changes are grouped into batches and passed to the fetched results controller to insert, update, or delete objects
/// from its managed results.
open class FetchedResultsStoreConnector<RequestType: FetchedResultsStoreRequest, ResultType: FetchedResultsStoreRequest.Result> {
    /// The controller used to batch incoming changes from the data store.
    let batchController = BatchController<ResultType>()
    
    /// Initializes a new store connector instance.
    public init() {
        
    }
    
    /// Executes the given fetch request.
    ///
    /// You must subclass this method and implement your own fetching logic. When data becomes available, call appropriate `enqueue` operation to update the receivers data.
    open func execute(_ request: RequestType) {
        
    }
    
    
    // MARK: -  Incremental Operations
    /// Proceses all enqueued changes immediately.
    ///
    /// You should use this method if you've enqueued changes driven by user action (e.g. user deleted an item).
    open func processPendingChanges() {
        batchController.processPendingChanges()
    }
    
    /// Enqueues the object as an insertion.
    open func enqueue(inserted: ResultType) {
        batchController.enqueue(inserted, as: .insert)
    }

    /// Enqueues the object as an update.
    open func enqueue(updated: ResultType) {
        batchController.enqueue(updated, as: .update)
    }
    
    /// Enqueues the object as an deletion.
    open func enqueue(removed: ResultType) {
        batchController.enqueue(removed, as: .remove)
    }
}
