//
//  RecursiveStoreConnector.swift
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

import FetchedResultsController

open class RecursiveStoreConnector<RequestType: FetchedResultsStoreRequest<ResultType>, ResultType: BaseResultObject>: CRUDStoreConnector<RequestType, ResultType> {
    // MARK: - Parent-Child Relationship
    /// The parent store connector of the recipient.
    public internal(set) weak var parent: RecursiveStoreConnector<RequestType, ResultType>?
    
    /// An array of store connectors that are children of the current store connector.
    public internal(set) var children: [RecursiveStoreConnector<RequestType, ResultType>] = []
    
    /// Adds the specified store connector as a child of the current store connector.
    ///
    /// This method creates a parent-child relationship between the current store connector and the object in the `child` parameter.
    ///
    /// - Note: This method calls `willMoveToParent(_:)` before adding the child, however it is expected that you call didMoveToParentViewController:
    open func addChild(_ child: RecursiveStoreConnector<RequestType, ResultType>) {
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
    open func willMoveToParent(_ parent: RecursiveStoreConnector<RequestType, ResultType>?) {
        
    }
    
    /// Called after the store connector is added or removed from another store connector.
    open func didMoveToParent(_ parent: RecursiveStoreConnector<RequestType, ResultType>?) {
        self.parent = parent
    }
    
    
    // MARK: - Draft CRUD Mode
    /// The draft batch.
    private let draft = Batch<ResultType>()
    
    /// Adds the object to the stores' results but tracks it as a draft insertion (i.e. does not commit to the underlying store).
    ///
    /// Call `commit()` to commit the changes to the underlying store.
    open func insertDraft(_ obj: ResultType) {
        draft.insert(obj)
        self.enqueue(inserted: obj)
    }
    
    /// Adds the object to the stores' results but tracks it as a draft update (i.e. does not commit to the underlying store).
    ///
    /// Call `commit()` to commit the changes to the underlying store.
    open func updateDraft(_ obj: ResultType) {
        draft.update(obj)
        self.enqueue(updated: obj)
    }
    
    /// Adds the object to the stores' results but tracks it as a draft delete (i.e. does not commit to the underlying store).
    ///
    /// Call `commit()` to commit the changes to the underlying store.
    open func deleteDraft(_ obj: ResultType) {
        draft.delete(obj)
        self.enqueue(removed: obj)
    }
    
    /// Commits draft objects to the underlying store.
    ///
    /// This method commits draft changes to the underlying store by calling the respective CRUD methods (i.e. `insert(_:)`, `udpate(_:)`, `delete(_:)`).
    open func commit(recursively: Bool = false) {
        // call `commit()` on each child if commiting recursively
        if recursively {
            children.forEach { $0.commit(recursively: true) }
        }
        
        // deduplicate draft objects for our level
        let result = draft.flush()
        
        // commit draft insertions
        for food in Array(result.inserted.values) {
            insert(food)
        }
        
        // commit draft updates
        for food in Array(result.updated.values) {
            update(food)
        }
        
        // commit draft deletions
        for food in Array(result.deleted.values) {
            delete(food)
        }
    }
}
