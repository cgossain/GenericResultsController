//
//  DataStore.swift
//
//  Copyright (c) 2023 Christian Gossain
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

/// DataStore is a generic abstract superclass that extends the base data store by adding API for querying
/// the store. It adds an additional generic parameter representing the request type.
///
/// You should subclass DataStore to build a custom connection to your data source. The API is
/// intentionally simple and makes no assumptions about how you manage your connection to the
/// underlying data store. Your concrete subclass should implement any state and logic needed to
/// efficiently communicate with your underlying store (i.e. opening connections, attaching
/// observers, closing connections, cleaning up, caching objects, etc.).
///
/// Results are delivered to the store query via a batching mechanism which optimizes diffs by
/// computing the diffs against a block of incremental changes rather than each time a change
/// is enqueued.
///
/// To deliver results, you call the `enqueue(_:_:)` method of the executed store query. How
/// you implement this is up to you. You can treat the query as long running by observing you database
/// and enqueing any changes into the query as they occur (possibly by capturing a reference to the
/// query in a closure).
///
/// The data store also provides a mechanism to display draft changes in a results controller (defined
/// in `BaseDataStore`) without commiting them to the underlying store (e.g. until the user taps
/// a "Save" button). It also provides a mechanism for managing parent-child relationships between
/// hierarchical data stores (e.g. sub-collections or relationships). This feature is currently used for
/// recursively commiting draft changes, but could be used for other purposes too).
///
/// See the example project for an example implementation using CoreData.
open class DataStore<ResultType: DataStoreResult, RequestType: DataStoreRequest>: BaseDataStore<ResultType> {
    
    /// The currently executing queries.
    public private(set) var queriesByID: [AnyHashable : DataStoreQuery<ResultType, RequestType>] = [:]
    
    // MARK: -  API
    
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
    open func execute(_ query: DataStoreQuery<ResultType, RequestType>) {
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
    open func stop(_ query: DataStoreQuery<ResultType, RequestType>) {
        queriesByID[query.id] = nil
    }
    
    // MARK: - BaseDataStore
    
    open override func insertDraft(_ obj: ResultType) {
        super.insertDraft(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        queriesByID.values.forEach { $0.enqueue([obj], as: .insert) }
    }
    
    open override func updateDraft(_ obj: ResultType) {
        super.updateDraft(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        queriesByID.values.forEach { $0.enqueue([obj], as: .update) }
    }
    
    open override func deleteDraft(_ obj: ResultType) {
        super.deleteDraft(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        queriesByID.values.forEach { $0.enqueue([obj], as: .delete) }
    }
}
