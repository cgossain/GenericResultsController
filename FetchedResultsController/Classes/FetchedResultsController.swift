//
//  FetchedResultsController.swift
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

/// The signature for a block that is run against fetched objects used to determine the section they belong to.
public typealias SectionNameProvider<T> = (_ obj: T) -> String?

/// A controller that you use to manage the results of a query performed against your database and to display data to the user.
open class FetchedResultsController<RequestType: StoreRequest> {
    /// The fetch request instance used to do the fetching. The sort descriptor used in the request groups objects into sections.
    public let storeRequest: RequestType
    
    /// The store connector instance the controller uses to execute a fetch request against.
    public let storeConnector: StoreConnector<RequestType>
    
    /// A block that is run against fetched objects used to determine the section they belong to.
    public let sectionNameProvider: SectionNameProvider<RequestType.ResultType>?
    
    /// The results of the fetch. Returns `nil` if `performFetch()` hasn't yet been called.
    public var fetchedObjects: [RequestType.ResultType] { return currentFetchedResults?.results ?? [] }

    /// The sections for the receiver’s fetch results.
    public var sections: [FetchedResultsSection<RequestType.ResultType>] { return currentFetchedResults?.sections ?? [] }
    
    /// The delegate handling all the results controller delegate callbacks.
    public var delegate = FetchedResultsControllerDelegate<RequestType>()
    
    /// The delegate handling all the results controller delegate callbacks.
    public var changeTracker = FetchedResultsControllerChangeTracking<RequestType>()
    
    
    // MARK: - Private Properties
    
    /// Indicates that a new fetch was started and that the current results object should be rebuilt
    /// instead of adding changes incrementally to the current results.
    private var shouldRebuildFetchedResults = false
    
    /// The current fetched results.
    private var currentFetchedResults: FetchedResults<RequestType>?
    
    /// A reference to the most recently executed query, and any subsequent pagination related queries.
    private var currentQueriesByID: [AnyHashable : ObserverQuery<RequestType>] = [:]
    
    /// The pagination cursor that points to the start of the next page.
    private var currentPaginationCursor: Any?
    
    /// A reference to the more recently executed query.
    private var currentQuery: ObserverQuery<RequestType>?
    
    
    
    // MARK: - Lifecycle
    
    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - Parameters:
    ///   - storeRequest: The request that will be executed against the store connector.
    ///   - storeConnector: The store connector instance which forms the connection to the underlying data store. The fetch request is executed against this connector instance.
    ///   - sectionNameProvider: A block that is run against fetched objects that returns the section name. Pass nil to indicate that the controller should generate a single section.
    public init(storeRequest: RequestType, storeConnector: StoreConnector<RequestType>, sectionNameProvider: SectionNameProvider<RequestType.ResultType>? = nil) {
        self.storeRequest = storeRequest
        self.storeConnector = storeConnector
        self.sectionNameProvider = sectionNameProvider
    }
    
    deinit {
        // cleanup by removing all
        // running queries
        stopCurrentQueries()
    }
    
    /// Executes a new query against the store connector.
    ///
    /// - Important: Calling this method invalidates any previous results.
    public func performFetch() {
        shouldRebuildFetchedResults = true
        
        // notify delegate
        delegate.controllerWillChangeContent?(self)
        
        // cleanup by removing all
        // running queries
        stopCurrentQueries()
        
        // making a copy of the store request ensures that even
        // if its properties are changed after `performFetch()`
        // is called, management of fetch objects remains consistent
        // internally until the next call to `performFetch()` where
        // a new snapshot of the fetch request would be taken
        let frozenStoreRequest = self.storeRequest.copy() as! RequestType
        
        // execute the new query
        let query = ObserverQuery<RequestType>(fetchRequest: frozenStoreRequest) { [unowned self] (digest) in
            let oldFetchedResults = self.currentFetchedResults ?? FetchedResults(storeRequest: self.storeRequest, sectionNameProvider: sectionNameProvider)
            
            var newFetchedResults: FetchedResults<RequestType>!
            if self.shouldRebuildFetchedResults {
                // add incremental changes starting from an empty results object
                newFetchedResults = FetchedResults(storeRequest: self.storeRequest, sectionNameProvider: sectionNameProvider)
                newFetchedResults.apply(digest: digest)
                
                // results rebuilt
                self.shouldRebuildFetchedResults = false
            }
            else {
                // add incremental changes starting from the current results
                newFetchedResults = FetchedResults(fetchedResults: oldFetchedResults)
                newFetchedResults.apply(digest: digest)
            }
            
            // update the current results
            self.currentFetchedResults = newFetchedResults

            // compute the difference if the change tracker is configured
            if let controllerDidChangeResults = self.changeTracker.controllerDidChangeResults {
                // compute the difference
                let diff = FetchedResultsDifference(from: oldFetchedResults, to: newFetchedResults, changedObjects: Array(digest.updated))
                controllerDidChangeResults(self, diff)
            }
            
            // notify the delegate
            self.delegate.controllerDidChangeContent?(self)
        }
        currentQueriesByID[query.id] = query
        storeConnector.execute(query)
    }
    
    /// Executes a query for the next page.
    func fetchNextPage() {
//        guard let currentPaginationCursor = currentPaginationCursor else {
//            return
//        }
        
        
    }
    
    /// Returns the snapshot at a given indexPath.
    ///
    /// - Parameters:
    ///     - indexPath: An index path in the fetch results. If indexPath does not describe a valid index path in the fetch results, an error is thrown.
    ///
    /// - Returns: The object at a given index path in the fetch results.
    public func object(at indexPath: IndexPath) throws -> RequestType.ResultType {
        if indexPath.section < sections.count {
            let section = sections[indexPath.section]
            
            if indexPath.row < section.numberOfObjects {
                return section.objects[indexPath.row]
            }
        }
        
        throw FetchedResultsControllerError.invalidIndexPath(row: indexPath.row, section: indexPath.section)
    }
    
    /// Returns the indexPath of a given object.
    ///
    /// - Parameters:
    ///     - obj: An object in the receiver’s fetch results.
    ///
    /// - Returns: The index path of object in the receiver’s fetch results, or nil if object could not be found.
    public func indexPath(for obj: RequestType.ResultType) -> IndexPath? {
        return currentFetchedResults?.indexPath(for: obj)
    }
}

extension FetchedResultsController {
    private func stopCurrentQueries() {
        currentQueriesByID.values.forEach({ storeConnector.stop($0) })
        currentQueriesByID.removeAll()
        currentPaginationCursor = nil
    }
}

extension FetchedResultsController: CustomStringConvertible {
    public var description: String {
        guard let description = currentFetchedResults?.description else {
            return "No fetched results. You must call `performFetch()`."
        }
        return description
    }
}
