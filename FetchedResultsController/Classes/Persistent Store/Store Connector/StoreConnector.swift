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
open class StoreConnector<ResultType: StoreResult, RequestType: StoreRequest>: BaseStore<ResultType> {
    
    // MARK: - Internal
    
    /// The currently executing queries.
    private(set) var queriesByID: [AnyHashable : StoreQuery<ResultType, RequestType>] = [:]
    
    
    // MARK: -  Lifecycle
    
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
    /// - Important: You must call `super.execute(_:)` at some point in your implementation.
    open func execute(_ query: StoreQuery<ResultType, RequestType>) {
        queriesByID[query.id] = query
        
        // leaving this as a thought:
        //
        // considering there could be multiple
        // active queries attached to this store, would it
        // instead make more sense to insert existing draft
        // changes into any new query that is added instead
        // of resetting them? would a subclass need to be
        // informed of this somehow?
        resetDraft()
    }
    
    /// Stops a long-running query.
    ///
    /// You need to override this method to perform any cleanup relating to stopping the query (e.g. removing database listeners).
    ///
    /// - Parameters:
    ///     - query: The query.
    ///
    /// - Important: You must call `super.stop(_:)` at some point in your implementation.
    open func stop(_ query: StoreQuery<ResultType, RequestType>) {
        queriesByID[query.id] = nil
    }
    
    
    // MARK: - CRUD Operations (Draft/Edit Mode)
    
    open override func insertDraft(_ obj: ResultType) {
        super.insertDraft(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        queriesByID.values.forEach { $0.enqueue(inserted: obj) }
    }
    
    open override func updateDraft(_ obj: ResultType) {
        super.updateDraft(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        queriesByID.values.forEach { $0.enqueue(updated: obj) }
    }
    
    open override func deleteDraft(_ obj: ResultType) {
        super.updateDraft(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        queriesByID.values.forEach { $0.enqueue(deleted: obj) }
    }
    
}
