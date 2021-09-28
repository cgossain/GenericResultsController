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

/// A controller that you use to manage the results of a query performed against your database and to display data to the user.
open class GenericResultsController<ResultType: StoreResult, RequestType: StoreRequest> {
    public enum State {
        /// Initial state.
        ///
        /// The controller starts off in this state and will remain in this
        /// state until the `performFetch()` method is called.
        case initial
        
        /// The controller is actively loading data.
        case loading
        
        /// The data has been fetched and sections updated.
        case loaded
    }
    
    // MARK: - Properties
    
    /// The store connector instance the controller uses to execute a fetch request against.
    public let storeConnector: StoreConnector<ResultType, RequestType>
    
    /// The results of the fetch. Returns `nil` if `performFetch()` hasn't yet been called.
    public var fetchedObjects: [ResultType] { return currentFetchedResults?.results ?? [] }

    /// The sections for the receiver’s fetch results.
    public var sections: [ResultsSection<ResultType>] { return currentFetchedResults?.sections ?? [] }
    
    /// The receivers' state.
    public var state: State = .initial
    
    
    // MARK: - Properties (Change Handling)
    
    /// The delegate handling all the results controller delegate callbacks.
    public var delegate = GenericResultsControllerDelegate<ResultType, RequestType>()
    
    /// The delegate handling all the results controller delegate callbacks.
    public var changeTracker = GenericResultsControllerChangeTracking<ResultType, RequestType>()
    
    
    // MARK: - Private Properties
    
    /// Indicates that a new fetch was started and that the results object should be
    /// rebuilt from scratch instead of incrementally adding changes to the current results.
    private var shouldRebuildFetchedResults = false
    
    /// A reference to the most recently executed query, and any subsequent pagination related queries.
    private var currentQueriesByID: [String : StoreQuery<ResultType, RequestType>] = [:]
    
    /// The current fetched results.
    private var currentFetchedResults: Results<ResultType, RequestType>?
    
    
    // MARK: - Lifecycle
    
    /// Creates and returns a new fetched results controller.
    ///
    /// - Parameters:
    ///   - storeConnector: The store connector instance which forms the connection to the underlying data store. The store request is executed against this connector instance.
    public init(storeConnector: StoreConnector<ResultType, RequestType>) {
        self.storeConnector = storeConnector
    }
    
    deinit {
        // cleanup by removing all
        // running queries
        stopCurrentQueries()
    }
    
    /// Executes a new query against the store connector.
    ///
    /// - Parameters:
    ///   - storeRequest: The search criteria used to retrieve data from a persistent store.
    ///
    /// - Important: Calling this method invalidates any previous results.
    public func performFetch(storeRequest: RequestType) {
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
        let resultsConfiguration = delegate.controllerResultsConfiguration?(self, storeRequest)
        
        // build and execute a new store query
        let query = StoreQuery<ResultType, RequestType>(storeRequest: storeRequest) { [unowned self] (result) in
            guard case let .success(success) = result else { return } // return if failed; content did not change
            
            let oldFetchedResults = self.currentFetchedResults ?? Results(storeRequest: storeRequest, resultsConfiguration: resultsConfiguration)
            
            var newFetchedResults: Results<ResultType, RequestType>!
            if self.shouldRebuildFetchedResults {
                // add incremental changes starting from an empty results object
                newFetchedResults = Results(storeRequest: storeRequest, resultsConfiguration: resultsConfiguration)
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

            // compute the difference if the change tracker is configured
            if let controllerDidChangeResults = self.changeTracker.controllerDidChangeResults {
                // compute the difference
                let diff = ResultsDifference(from: oldFetchedResults, to: newFetchedResults, changedObjects: success.updated)
                controllerDidChangeResults(self, diff)
            }
            
            // notify the delegate
            self.delegate.controllerDidChangeContent?(self)
        }
        currentQueriesByID[query.id] = query
        storeConnector.execute(query)
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
        currentQueriesByID.values.forEach({ storeConnector.stop($0) })
        currentQueriesByID.removeAll()
    }
}

extension GenericResultsController: CustomStringConvertible {
    public var description: String {
        guard let description = currentFetchedResults?.description else {
            return "No fetched results. Call `performFetch()`."
        }
        
        return description
    }
}
