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

/// A type that fetched objects must conform to.
public typealias StoreResult = Identifiable & Hashable

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
open class StoreConnector<ResultType: StoreResult, RequestType: StoreRequest>: Identifiable {
    /// The stable identity of the entity associated with this instance.
    public let id: String
    
    /// A short descriptive title for the data store.
    public let title: String
    
    /// Currently executing queries.
    private(set) var queriesByID: [AnyHashable : StoreQuery<ResultType, RequestType>] = [:]
    
    
    // MARK: -  Lifecycle
    
    /// Initializes a new store connector instance.
    public init(id: String? = nil, title: String = "") {
        self.id = id ?? title.lowercased()
        self.title = title
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
    /// - Important: You must call `try super.execute(_:)` at some point in your implementation.
    open func execute(_ query: StoreQuery<ResultType, RequestType>) throws {
        queriesByID[query.id] = query
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
    
    
    // MARK: - Managing Parent-Child Relationship
    
    /// The parent store connector of the recipient.
    public internal(set) weak var parent: StoreConnector<ResultType, RequestType>?
    
    /// An array of store connectors that are children of the current store connector.
    public internal(set) var children: [StoreConnector<ResultType, RequestType>] = []
    
    /// Adds the specified store connector as a child of the current store connector.
    ///
    /// This method creates a parent-child relationship between the current store connector and the object in the `child` parameter.
    ///
    /// - Note: This method calls `willMoveToParent(_:)` before adding the child, however it is expected that you call didMoveToParentViewController:
    open func addChild(_ child: StoreConnector<ResultType, RequestType>) {
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
    open func willMoveToParent(_ parent: StoreConnector<ResultType, RequestType>?) {
        
    }
    
    /// Called after the store connector is added or removed from another store connector.
    open func didMoveToParent(_ parent: StoreConnector<ResultType, RequestType>?) {
        self.parent = parent
    }
    
}

extension StoreConnector: Equatable {
    public static func == (lhs: StoreConnector<ResultType, RequestType>, rhs: StoreConnector<ResultType, RequestType>) -> Bool {
        return lhs.id == rhs.id
    }
}
