//
//  BaseStore.swift
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

/// A type that fetched objects must conform to.
public typealias StoreResult = InstanceIdentifiable & Hashable

/// BaseStore is an abstract superclass that adds some convenient features to the
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
open class BaseStore<ResultType: StoreResult>: InstanceIdentifiable {
    
    /// The stable identity of the entity associated with this instance.
    public let id: String
    
    /// A short descriptive title for the store.
    public let title: String
    
    
    // MARK: - Internal
    
    /// The draft batch.
    private(set) var draft = Batch<ResultType>(id: UUID().uuidString)
    
    
    // MARK: -  Lifecycle
    
    /// Creates and returns a new store instance.
    ///
    /// - Parameters:
    ///     - id: An identifier for this store.
    ///     - title: A short descriptive title for the store.
    public init(id: String? = nil, title: String = "") {
        self.id = id ?? title.lowercased()
        self.title = title
    }
    
    
    // MARK: - CRUD Operations
    
    /// Inserts the object into the underlying store.
    ///
    /// - Important: You must call `super.insert(_:)` at some point in your implementation.
    open func insert(_ obj: ResultType) {
        
    }
    
    /// Updates the object in the underlying store.
    ///
    /// - Important: You must call `super.update(_:)` at some point in your implementation.
    open func update(_ obj: ResultType) {
        
    }
    
    /// Deletes the object from the underlying store.
    ///
    /// - Important: You must call `super.delete(_:)` at some point in your implementation.
    open func delete(_ obj: ResultType) {
        
    }
    
    
    // MARK: - CRUD Operations (Draft/Edit Mode)
    
    /// Tracks the insertion in the stores' internal draft, and enqueues it into any
    /// running queries (i.e. does not commit to the underlying store).
    ///
    /// Call `commitDraft()` to commit the changes to the underlying store.
    open func insertDraft(_ obj: ResultType) {
        draft.insert(obj)
    }
    
    /// Tracks the update in the stores' internal draft, and enqueues it into any
    /// running queries (i.e. does not commit to the underlying store).
    ///
    /// Call `commitDraft()` to commit the changes to the underlying store.
    open func updateDraft(_ obj: ResultType) {
        draft.update(obj)
    }
    
    /// Tracks the deletion in the stores' internal draft, and enqueues it into any
    /// running queries (i.e. does not commit to the underlying store).
    ///
    /// Call `commitDraft()` to commit the changes to the underlying store.
    open func deleteDraft(_ obj: ResultType) {
        draft.delete(obj)
    }
    
    /// Commits draft objects to the underlying store.
    ///
    /// This method commits draft changes to the underlying store by calling the respective CRUD methods (i.e. `insert(_:)`, `udpate(_:)`, `delete(_:)`).
    ///
    /// - Parameters:
    ///     - recursively: Indicates if the commit should propagate through to child CRUD stores.
    ///
    /// - Important: Do not call `super.update(_:)` in your implementation.
    open func commitDraft(recursively: Bool = false) {
        if recursively {
            children.forEach { $0.commitDraft(recursively: true) }
        }
        
        // deduplicated draft changes, then commit
        let digest = draft.flush()
        digest.inserted.forEach({ insert($0) })
        digest.updated.forEach({ update($0) })
        digest.deleted.forEach({ delete($0) })
        
        // reset the draft after commiting changes
        resetDraft()
    }
    
    /// Clears all draft changes without commiting them.
    open func resetDraft() {
        draft = Batch<ResultType>(id: UUID().uuidString)
    }
    
    
    // MARK: - Managing Parent-Child Relationship
    
    /// The parent store connector of the recipient.
    public internal(set) weak var parent: BaseStore<ResultType>?
    
    /// An array of store connectors that are children of the current store connector.
    public internal(set) var children: [BaseStore<ResultType>] = []
    
    /// Adds the specified store connector as a child of the current store connector.
    ///
    /// This method creates a parent-child relationship between the current store connector and the object in the `child` parameter.
    ///
    /// - Note: This method calls `willMoveToParent(_:)` before adding the child, however it is expected that you call didMoveToParentViewController:
    open func addChild(_ child: BaseStore<ResultType>) {
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
    open func willMoveToParent(_ parent: BaseStore<ResultType>?) {
        
    }
    
    /// Called after the store connector is added or removed from another store connector.
    open func didMoveToParent(_ parent: BaseStore<ResultType>?) {
        self.parent = parent
    }
    
}

extension BaseStore: Equatable {
    public static func == (lhs: BaseStore<ResultType>, rhs: BaseStore<ResultType>) -> Bool {
        return lhs.id == rhs.id
    }
}
