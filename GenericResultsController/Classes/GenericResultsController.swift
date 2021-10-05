//
//  GenericResultsController.swift
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

/// A controller that you use to manage the results of a query performed against a data store and to display that data to the user.
///
/// The results controller provides a diffing mechanism that batches changes together such that the diff is only computed on a
/// larger blocks of changes. To receive diff updates just configure (or set) the `changeTracker` parameter.
public final class GenericResultsController<ResultType: DataStoreResult, RequestType: DataStoreRequest> {
    public enum State {
        /// Initial state.
        ///
        /// The controller starts off in this state and will 
        /// remain in this state until the `performFetch(_:)` 
        /// method is called for the first time.
        case initial
        
        /// The controller is actively loading data.
        case loading
        
        /// The data has been fetched and sections updated.
        case loaded
    }
    
    // MARK: - Properties
    
    /// The data store instance.
    ///
    /// The controller queries the data store instance to fetch and receive results which it then
    /// arranges into sections according to the results configuration specified by your delegate.
    ///
    /// - Note: A new query is executed against this store instance whenever `performFetch(_:)` is called.
    public let store: DataStore<ResultType, RequestType>
    
    /// The results of the fetch.
    ///
    /// This is the entire set of result objects ordered into a single array according to the
    /// results configuration specified by your delegate (e.g. first by section, then by
    /// the `areInIncreasingOrder` predicate).
    ///
    /// Returns `nil` if `performFetch(_:)` hasn't been called yet.
    public var fetchedObjects: [ResultType] { return currentFetchedResults?.results ?? [] }
    
    /// The sections.
    ///
    /// When `performFetch(_:)` is called, a new query is executed against the `store` instance. Whenever the
    /// query returns results (e.g. initial or incremental), the controller will arrange these into 1 or more sections according
    /// to the results configuration specified by your delegate. This is the property you'll primarily interact with when binding
    /// to your UI. Your table and collections view data source implementations can query this property to determine the
    /// number of sections and number of objects in each section.
    public var sections: [ResultsSection<ResultType>] { return currentFetchedResults?.sections ?? [] }
    
    /// The receivers' state.
    public var state: State = .initial
    
    
    // MARK: - Properties (Change Handling)
    
    /// The delegate object that will receive all delegate callbacks.
    public var delegate = GenericResultsControllerDelegate<ResultType, RequestType>()
    
    /// The delegate object that will receive all diffing callbacks.
    public var changeTracker = GenericResultsControllerChangeTracking<ResultType, RequestType>()
    
    
    // MARK: - Private Properties
    
    /// A flag that indicates that a new fetch was started and that the results object should be
    /// rebuilt from scratch instead of incrementally adding changes to the current results.
    private var shouldRebuildFetchedResults = false
    
    /// A reference to all queries executed by the receiver against the data store.
    private var currentQueriesByID: [String : DataStoreQuery<ResultType, RequestType>] = [:]
    
    /// The current fetched results.
    private var currentFetchedResults: Results<ResultType, RequestType>?
    
    
    // MARK: - Lifecycle
    
    /// Creates and returns a new fetched results controller.
    ///
    /// - Parameters:
    ///   - store: The data store instance.
    public init(store: DataStore<ResultType, RequestType>) {
        self.store = store
    }
    
    deinit {
        // cleanup by removing all
        // running queries
        stopCurrentQueries()
    }
    
    /// Executes a new query against the data store.
    ///
    /// - Parameters:
    ///   - request: The search criteria used to retrieve data from a persistent store.
    ///
    /// - Note: Calling this method first stops any and all queries previously executed against the data store by the receiver, and invalidates the current results set.
    public func performFetch(request: RequestType) {
        // update state
        state = .loading
        
        // update flag
        shouldRebuildFetchedResults = true
        
        // notify delegate
        delegate.controllerWillChangeContent?(self)
        
        // cleanup by removing all
        // running queries
        stopCurrentQueries()
        
        // get the results configuration
        let resultsConfiguration = delegate.controllerResultsConfiguration?(self, request)
        
        // build and execute a new store query
        let query = DataStoreQuery<ResultType, RequestType>(request: request) { [unowned self] (result) in
            guard case let .success(success) = result else { return } // return if failed; content did not change
            
            let oldFetchedResults = self.currentFetchedResults ?? Results(storeRequest: request, resultsConfiguration: resultsConfiguration)
            
            var newFetchedResults: Results<ResultType, RequestType>!
            if self.shouldRebuildFetchedResults {
                // add incremental changes starting from an empty results object
                newFetchedResults = Results(storeRequest: request, resultsConfiguration: resultsConfiguration)
                newFetchedResults.apply(inserted: success.inserted, updated: success.updated, deleted: success.deleted)
                
                // fetched results have been rebuilt
                self.shouldRebuildFetchedResults = false
            }
            else {
                // add incremental changes starting from the current results
                newFetchedResults = Results(fetchedResults: oldFetchedResults)
                newFetchedResults.apply(inserted: success.inserted, updated: success.updated, deleted: success.deleted)
            }
            
            // update the current results
            self.currentFetchedResults = newFetchedResults
            
            // update state
            self.state = .loaded

            // compute difference if the change tracker is configured
            if let controllerDidChangeResults = self.changeTracker.controllerDidChangeResults {
                // compute the difference
                let diff = ResultsDifference(from: oldFetchedResults, to: newFetchedResults, changedObjects: success.updated)
                controllerDidChangeResults(self, diff)
            }
            
            // notify the delegate
            self.delegate.controllerDidChangeContent?(self)
        }
        currentQueriesByID[query.id] = query
        store.execute(query)
    }
    
    /// Returns the object at a given index path.
    ///
    /// - Parameters:
    ///     - indexPath: An index path in the fetch results. If indexPath does not describe a valid index path in the fetch results, an error is thrown.
    ///
    /// - Returns: The object at a given index path in the fetch results.
    public func object(at indexPath: IndexPath) throws -> ResultType {
        if indexPath.section < sections.count {
            let section = sections[indexPath.section]
            
            if indexPath.row < section.numberOfObjects {
                return section.objects[indexPath.row]
            }
        }
        
        throw GenericResultsControllerError.invalidIndexPath(row: indexPath.row, section: indexPath.section)
    }
    
    /// Returns the index path of a given object.
    ///
    /// - Parameters:
    ///     - obj: An object in the receiver’s fetch results.
    ///
    /// - Returns: The index path of object in the receiver’s fetch results, or nil if object could not be found.
    public func indexPath(for obj: ResultType) -> IndexPath? {
        return currentFetchedResults?.indexPath(for: obj)
    }
}

extension GenericResultsController {
    private func stopCurrentQueries() {
        currentQueriesByID.values.forEach({ store.stop($0) })
        currentQueriesByID.removeAll()
    }
}

extension GenericResultsController: CustomStringConvertible {
    public var description: String {
        guard let description = currentFetchedResults?.description else {
            return "No fetched results. Call `performFetch(_:)`."
        }
        
        return description
    }
}
