//
//  CRUDStoreConnector.swift
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

/// CRUDStoreConnector is an abstract superclass that adds insert, update, and delete
/// methods to the base store connector.
///
/// It also adds a mechanism for tracking draft changes, and managing parent-child relationships
/// between store connectors (which is used to recursively commit draft changes, but could
/// be used for other purposes too).
///
/// This class is provided for convenience. Given that the base store connector should already understand the
/// particulars of fetching data from the underlying store (i.e. `func execute(_ request: RequestType)`),
/// it follows that if one wanted to also perform CRUD operations on that same store (or specific location in that store)
/// this would be the logical place to do it.
///
/// - Note: The results controller does not call any of these methods itself.
open class CRUDStoreConnector<ResultType: FetchRequestResult, RequestType: FetchRequest<ResultType>>: StoreConnector<ResultType, RequestType> {
    
    // MARK: - Private Properties
    
    /// The draft batch.
    private var draft = Batch<ResultType>(id: UUID().uuidString)
    
    
    // MARK: - StoreConnector
    
    public override init(title: String = "") {
        super.init(title: title)
        
    }
    
    open override func execute(_ query: ObserverQuery<ResultType, RequestType>) {
        super.execute(query)
        
        // reset the draft on execution of a new query
        draft = Batch<ResultType>(id: UUID().uuidString)
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
    
    /// Adds the object to the stores' results but tracks it as a draft insertion (i.e. does not commit to the underlying store).
    ///
    /// Call `commit()` to commit the changes to the underlying store.
    open func insertDraft(_ obj: ResultType) {
        draft.insert(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        queryByID.values.forEach { self.enqueue(inserted: obj, for: $0) }
    }
    
    /// Adds the object to the stores' results but tracks it as a draft update (i.e. does not commit to the underlying store).
    ///
    /// Call `commit()` to commit the changes to the underlying store.
    open func updateDraft(_ obj: ResultType) {
        draft.update(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        queryByID.values.forEach { self.enqueue(updated: obj, for: $0) }
    }
    
    /// Adds the object to the stores' results but tracks it as a draft delete (i.e. does not commit to the underlying store).
    ///
    /// Call `commit()` to commit the changes to the underlying store.
    open func deleteDraft(_ obj: ResultType) {
        draft.delete(obj)
        
        // a CRUD operation would affect all
        // active queries; the filter and sort
        // configuration on the fetch request
        // will take care of correctly showing
        // this object (or not) in the UI
        queryByID.values.forEach { self.enqueue(deleted: obj, for: $0) }
    }
    
    /// Commits draft objects to the underlying store.
    ///
    /// This method commits draft changes to the underlying store by calling the respective CRUD methods (i.e. `insert(_:)`, `udpate(_:)`, `delete(_:)`).
    ///
    /// - Parameters:
    ///     - recursively: Indicates if the commit should propagate through to child CRUD stores.
    open func commit(recursively: Bool = false) {
        // call `commit()` on each child store (if commiting recursively)
        if recursively {
            children.forEach { $0.commit(recursively: true) }
        }
        
        // deduplicate draft objects for our level
        let digest = draft.flush()
        
        // commit draft insertions
        for food in digest.inserted {
            insert(food)
        }
        
        // commit draft updates
        for food in digest.updated {
            update(food)
        }
        
        // commit draft deletions
        for food in digest.deleted {
            delete(food)
        }
        
        // reset the draft after commiting
        draft = Batch<ResultType>(id: UUID().uuidString)
    }
    
    
    // MARK: - Managing Parent-Child Relationship
    
    /// The parent store connector of the recipient.
    public internal(set) weak var parent: CRUDStoreConnector<ResultType, RequestType>?
    
    /// An array of store connectors that are children of the current store connector.
    public internal(set) var children: [CRUDStoreConnector<ResultType, RequestType>] = []
    
    /// Adds the specified store connector as a child of the current store connector.
    ///
    /// This method creates a parent-child relationship between the current store connector and the object in the `child` parameter.
    ///
    /// - Note: This method calls `willMoveToParent(_:)` before adding the child, however it is expected that you call didMoveToParentViewController:
    open func addChild(_ child: CRUDStoreConnector<ResultType, RequestType>) {
        // remove from existing parent if needed
        if let parent = child.parent {
            parent.removeFromParent()
        }
        
        child.willMoveToParent(self)
        children.append(child)
    }
    
    /// Removes the store connector from its parent.
    open func removeFromParent() {
        guard let idx = parent?.children.firstIndex(of: self) else { return }
        parent?.children.remove(at: idx)
        didMoveToParent(nil)
    }
    
    /// Called just before the store connector is added or removed from another store connector.
    open func willMoveToParent(_ parent: CRUDStoreConnector<ResultType, RequestType>?) {
        
    }
    
    /// Called after the store connector is added or removed from another store connector.
    open func didMoveToParent(_ parent: CRUDStoreConnector<ResultType, RequestType>?) {
        self.parent = parent
    }
}
