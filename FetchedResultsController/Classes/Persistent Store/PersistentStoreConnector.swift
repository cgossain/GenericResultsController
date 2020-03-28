//
//  PersistentStoreConnector.swift
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

/// PersistentStoreConnector is an abstract superclass defining a simple API to communicate with between an instance of
/// fetched results controller and any data store. This superclass is intended to be a stateless adapter to some database.
///
/// The provided API is intentionally basic and makes no assumptions about how you manage the connection to some underlying
/// store. Your subclass should implement any state and logic related to communicating with the underlying store including
/// opening, closing, cleaning up, and setting up observers.
open class PersistentStoreConnector<RequestType: PersistentStoreRequest, ResultType: FetchRequestResult> {
    /// Initializes a new persistent store connector instance.
    public init() {
        
    }
    
    /// Executes the given fetch request.
    ///
    /// You must subclass this method and implement your own fetching logic. When data becomes available, call appropriate `enqueue` operation to update the receivers data.
    open func execute(_ request: RequestType) {
        
    }
    
    
    // MARK: -  Incremental Operations
    /// The controller used to batch incoming changes from the persistent store.
    let batchController = BatchController<ResultType>()
    
    // 1. value added
    // 2. value changed/moved
    // 3. value removed
    // 4. fetch request refreshed
    
    /// Enqueues the object as an insertion.
    open func enqueue(inserted: ResultType) {
        batchController.enqueue(inserted, with: .insert)
    }

    /// Enqueues the object as an update.
    open func enqueue(updated: ResultType) {
        batchController.enqueue(updated, with: .update)
    }
    
    /// Enqueues the object as an deletion.
    open func enqueue(removed: ResultType) {
        batchController.enqueue(removed, with: .remove)
    }
    
    /// Proceses all enqueued changes immediately.
    func processPendingChanges() {
        batchController.processPendingChanges()
    }
}
