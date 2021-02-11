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
open class FetchedResultsController<ResultType: FetchRequestResult, RequestType: FetchRequest<ResultType>> {
    /// The store connector instance the controller uses to execute a fetch request against.
    public let storeConnector: StoreConnector<ResultType, RequestType>
    
    /// The fetch request instance used to do the fetching. The sort descriptor used in the request groups objects into sections.
    public let fetchRequest: RequestType
    
    /// A block that is run against fetched objects used to determine the section they belong to.
    public let sectionNameProvider: SectionNameProvider<ResultType>?
    
    /// The results of the fetch. Returns `nil` if `performFetch()` hasn't yet been called.
    public var fetchedObjects: [ResultType] { return currentFetchedResults?.results ?? [] }

    /// The sections for the receiver’s fetch results.
    public var sections: [FetchedResultsSection<ResultType>] { return currentFetchedResults?.sections ?? [] }
    
    /// The delegate handling all the results controller delegate callbacks.
    public var delegate = FetchedResultsControllerDelegate<ResultType, RequestType>()
    
    /// The delegate handling all the results controller delegate callbacks.
    public var changeTracker = FetchedResultsControllerChangeTracking<ResultType, RequestType>()
    
    
    // MARK: - Private Properties
    
    /// The current fetched results.
    private var currentFetchedResults: FetchedResults<ResultType>?
    
    /// A reference to the more recently executed query.
    private var currentQuery: ObserverQuery<ResultType, RequestType>?
    
    /// Indicates that a new fetch was started and that the current results object should be rebuilt
    /// instead of adding changes incrementally to the current results.
    private var shouldRebuildFetchedResults = false
    
    
    // MARK: - Lifecycle
    
    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - Parameters:
    ///   - fetchRequest: The fetch request that will be executed against the store connector.
    ///   - storeConnector: The store connector instance which forms the connection to the underlying data store. The fetch request is executed against this connector instance.
    ///   - sectionNameProvider: A block that is run against fetched objects that returns the section name. Pass nil to indicate that the controller should generate a single section.
    public init(fetchRequest: RequestType, storeConnector: StoreConnector<ResultType, RequestType>, sectionNameProvider: SectionNameProvider<ResultType>? = nil) {
        self.fetchRequest = fetchRequest
        self.storeConnector = storeConnector
        self.sectionNameProvider = sectionNameProvider
    }
    
    deinit {
        // cleanup by removing any currently
        // running queries
        if let currentQuery = currentQuery {
            storeConnector.stop(currentQuery)
        }
    }
    
    /// Executes the current store request against the store connector.
    ///
    /// - Important: Calling this method effectively invalidates any previous results.
    public func performFetch() {
        shouldRebuildFetchedResults = true
        
        // notify delegate
        delegate.controllerWillChangeContent?(self)
        
        // cleanup by stopping the currently
        // running query if needed
        if let currentQuery = currentQuery {
            storeConnector.stop(currentQuery)
        }
        
        // make a copy of the fetch request at the
        // time `performFetch()` is called to ensure
        // incremental changes are applyed against a
        // stable fetch request; the expectation is that
        // if the fetch parameters are changed, `performFetch()`
        // will be called again
        let frozenFetchRequest = fetchRequest.copy() as! RequestType
        
        // execute the new query
        let query = ObserverQuery(fetchRequest: frozenFetchRequest) { [unowned self] (digest) in
            let oldFetchedResults = self.currentFetchedResults ?? FetchedResults(fetchRequest: frozenFetchRequest, sectionNameProvider: sectionNameProvider)
            
            var newFetchedResults: FetchedResults<ResultType>!
            if self.shouldRebuildFetchedResults {
                // add incremental changes starting from an empty results object
                newFetchedResults = FetchedResults(fetchRequest: frozenFetchRequest, sectionNameProvider: sectionNameProvider)
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
        currentQuery = query
        storeConnector.execute(query)
    }
    
    /// Returns the snapshot at a given indexPath.
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
        
        throw FetchedResultsControllerError.invalidIndexPath(row: indexPath.row, section: indexPath.section)
    }
    
    /// Returns the indexPath of a given object.
    ///
    /// - Parameters:
    ///     - obj: An object in the receiver’s fetch results.
    ///
    /// - Returns: The index path of object in the receiver’s fetch results, or nil if object could not be found.
    public func indexPath(for obj: ResultType) -> IndexPath? {
        return currentFetchedResults?.indexPath(for: obj)
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
