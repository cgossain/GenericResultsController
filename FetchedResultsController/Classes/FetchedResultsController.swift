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

/// A type that fetched objects must conform to.
public typealias BaseResultObject = Identifiable & Hashable

/// The signature for a block that is run against fetched objects used to determine the section they belong to.
public typealias SectionNameProvider<T> = (_ obj: T) -> String

/// A controller that you use to manage the results of a query performed against your database and to display data to the user.
open class FetchedResultsController<RequestType: StoreRequest<ResultType>, ResultType: BaseResultObject> {
    /// The store connector instance the controller uses to execute a fetch request against.
    public let storeConnector: StoreConnector<RequestType, ResultType>
    
    /// The fetch request instance used to do the fetching. The sort descriptor used in the request groups objects into sections.
    public let fetchRequest: RequestType
    
    /// A block that is run against fetched objects used to determine the section they belong to.
    public let sectionNameProvider: SectionNameProvider<ResultType>?
    
    /// The results of the fetch. Returns `nil` if `performFetch()` hasn't yet been called.
    public var fetchedObjects: [ResultType] { return currentFetchedResults?.results ?? [] }

    /// The sections for the receiver’s fetch results.
    public var sections: [FetchedResultsSection<ResultType>] { return currentFetchedResults?.sections ?? [] }
    
    /// The delegate handling all the results controller delegate callbacks.
    public var delegate = FetchedResultsControllerDelegate<RequestType, ResultType>()
    
    /// The delegate handling all the results controller delegate callbacks.
    public var changeTracker = FetchedResultsControllerChangeTracking<RequestType, ResultType>()
    
    
    // MARK: - Private Properties
    /// The current fetched results.
    private var currentFetchedResults: FetchedResults<ResultType>?
    
    /// This value is incremented each time `-execute` is called.
    ///
    /// When executing an asynchronous fetch, you can use this value to validate that the
    /// handle has not changed between when `-execute` is called and the asynchronous
    /// results are returned. If the handle has changed, you can discard the returned results.
    public private(set) var currentFetchHandle = 0
    
    
    // MARK: - Lifecycle
    /// Returns a fetch request controller initialized using the given arguments.
    ///
    /// - parameters:
    ///   - storeConnector: The store connector instance which forms the connection to the underlying data store. The fetch request is executed against this connector instance.
    ///   - fetchRequest: The fetch request that will be executed against the store connector.
    ///   - sectionNameKeyPath: A key path on result objects that returns the section name. Pass nil to indicate that the controller should generate a single section.
    ///   - sectionNameProvider: A block that is run against fetched objects used to determine the section they belong to.
    public init(storeConnector: StoreConnector<RequestType, ResultType>, fetchRequest: RequestType, sectionNameProvider: SectionNameProvider<ResultType>? = nil) {
        self.storeConnector = storeConnector
        self.fetchRequest = fetchRequest
        self.sectionNameProvider = sectionNameProvider
    }
    
    /// Executes the fetch request and begins observing further changes to the data store.
    public func performFetch() {
        // TODO: Test if we should send a delegate callback at this point to allow a UITableView to clear our its contents?
        currentFetchHandle += 1
        
        // since we're starting a new fetch we'll wipe out our current
        // results and start fresh with an empty fetched results object
        currentFetchedResults = FetchedResults(isIncluded: fetchRequest.isIncluded,
                                               areInIncreasingOrder: fetchRequest.areInIncreasingOrder,
                                               sectionNameProvider: sectionNameProvider)
        
        // notify delegate
        delegate.controllerWillChangeContent?(self)
        
        // attach callbacks to the store connectors' internal batch controller
        storeConnector.batchController.delegate.controllerWillBeginBatchingChanges = { [unowned self] (controller) in
            self.delegate.controllerWillChangeContent?(self)
        }
        
        storeConnector.batchController.delegate.controllerDidFinishBatchingChanges = { [unowned self] (controller, inserted, updated, deleted) in
            // keep track of the current results (before applying the changes)
            let oldFetchedResults: FetchedResults<ResultType>! = self.currentFetchedResults
            
            // starting from the current resuts, apply the changes to a new fetched results
            // object; note that force unwraping the current fetched results here is safe
            // since we've creating it at the start of the `performFetch()` method
            let newFetchedResults = FetchedResults(fetchedResults: self.currentFetchedResults!)
            newFetchedResults.apply(inserted: Array(inserted), changed: Array(updated), deleted: Array(deleted))
            
            // update the current results
            self.currentFetchedResults = newFetchedResults
            
            // compute the difference if the change tracker is configured
            if let controllerDidChangeResults = self.changeTracker.controllerDidChangeResults {
                // compute the difference
                let diff = FetchedResultsDifference(from: oldFetchedResults, to: newFetchedResults, changedObjects: Array(updated))
                controllerDidChangeResults(self, diff)
            }
            
            // notify the delegate
            self.delegate.controllerDidChangeContent?(self)
        }
        
        // execute the fetch
        storeConnector.execute(fetchRequest)
    }
    
    /// Returns the snapshot at a given indexPath.
    ///
    /// - parameters:
    ///     - indexPath: An index path in the fetch results. If indexPath does not describe a valid index path in the fetch results, an error is thrown.
    ///
    /// - returns: The object at a given index path in the fetch results.
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
    /// - parameters:
    ///     - obj: An object in the receiver’s fetch results.
    ///
    /// - returns: The index path of object in the receiver’s fetch results, or nil if object could not be found.
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
