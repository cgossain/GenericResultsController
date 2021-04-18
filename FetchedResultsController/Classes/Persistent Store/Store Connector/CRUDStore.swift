//
//  CRUDStore.swift
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

/// CRUDStore is an abstract superclass that adds some convenient features to the
/// base store connector.
///
/// In particular, it defines an API for insert, update, and delete operations. It also adds a
/// mechanism for tracking draft changes (shows in the UI but not commited to the store),
/// and finally it also a mechanism for managing parent-child relationships between store
/// connectors (which is used to recursively commit draft changes, but could be used for
/// other purposes too).
///
/// Given that the base store connector should already understand the particulars of fetching
/// data from the underlying store, it follows that if one wanted to also perform CRUD operations
/// on that same store (or specific location in that store) this would be the logical place to do it.
open class CRUDStore<ResultType: StoreResult, RequestType: StoreRequest>: StoreConnector<ResultType, RequestType> {
    
    /// Active observer queries by ID.
    private var observerQueriesByID: [AnyHashable : StoreQuery<ResultType, RequestType>] = [:]
    
    
    // MARK: - Private Properties
    
    /// The draft batch.
    private var draft = Batch<ResultType>(id: UUID().uuidString)
    
    
    // MARK: - StoreConnector
    
    /// You must call `super.execute(_:)`. The CRUD store does some internal setup in this method.
    open override func execute(_ query: StoreQuery<ResultType, RequestType>) throws {
        draft = Batch<ResultType>(id: UUID().uuidString)
        
        if let observerQuery = query as? StoreQuery<ResultType, RequestType> {
            observerQueriesByID[observerQuery.id] = observerQuery
        }
    }
    
    /// Stops a long-running query.
    ///
    /// You need to override this method to perform any cleanup relating to stopping the query (e.g. removing database listeners).
    ///
    /// - Parameters:
    ///     - query: The query.
    ///
    /// - Note: You must call `super.stop(_:)`. The CRUD store does some internal cleanup in this method.
    open override func stop(_ query: StoreQuery<ResultType, RequestType>) {
        observerQueriesByID[query.id] = nil
    }
    
    
    // MARK: - CRUD
    
    /// Inserts the object into the underlying store.
    open func insert(_ obj: ResultType) {
        
    }
    
    /// Updates the object in the underlying store.
    open func update(_ obj: ResultType) {
        
    }
    
    /// Deletes the object from the underlying store.
    open func delete(_ obj: ResultType) {
        
    }
    
    
    // MARK: - CRUD (Draft Mode)
    
    /// Tracks the insertion in the stores' internal draft, and enqueues it into any running
    /// observer queries (i.e. does not commit to the underlying store).
    ///
    /// Call `commit()` to commit the changes to the underlying store.
    open func insertDraft(_ obj: ResultType) {
        draft.insert(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        observerQueriesByID.values.forEach { $0.enqueue(inserted: obj) }
    }
    
    /// Tracks the update in the stores' internal draft, and enqueues it into any running
    /// observer queries (i.e. does not commit to the underlying store).
    ///
    /// Call `commit()` to commit the changes to the underlying store.
    open func updateDraft(_ obj: ResultType) {
        draft.update(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        observerQueriesByID.values.forEach { $0.enqueue(updated: obj) }
    }
    
    /// Tracks the deletion in the stores' internal draft, and enqueues it into any running
    /// observer queries (i.e. does not commit to the underlying store).
    ///
    /// Call `commit()` to commit the changes to the underlying store.
    open func deleteDraft(_ obj: ResultType) {
        draft.delete(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        observerQueriesByID.values.forEach { $0.enqueue(deleted: obj) }
    }
    
    /// Commits draft objects to the underlying store.
    ///
    /// This method commits draft changes to the underlying store by calling the respective CRUD methods (i.e. `insert(_:)`, `udpate(_:)`, `delete(_:)`).
    ///
    /// - Parameters:
    ///     - recursively: Indicates if the commit should propagate through to child CRUD stores.
    open func commit(recursively: Bool = false) {
        // call `commit()` on each child
        // CRUD store (if commiting recursively)
        if recursively {
            children.compactMap({ $0 as? CRUDStore }).forEach { $0.commit(recursively: true) }
        }
        
        // commit any deduplicated draft changes
        let digest = draft.flush()
        digest.inserted.forEach({ self.insert($0) })
        digest.updated.forEach({ self.update($0) })
        digest.deleted.forEach({ self.delete($0) })
        
        // reset the draft after commiting
        draft = Batch<ResultType>(id: UUID().uuidString)
    }
    
}
