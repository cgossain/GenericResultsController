//
//  FetchedResultsController.swift
//
//  Copyright (c) 2017-2020 Christian Gossain
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

public enum FetchedResultsControllerError: Error {
    case invalidIndexPath(row: Int, section: Int)
}

/// Use FetchedResultsController to manage the results of a query performed against your database and to display the results to the user.
open class FetchedResultsController<RequestType: FetchedResultsStoreRequest, ResultType: FetchedResultsStoreRequest.Result> {
    /// The fetch request instance used to do the fetching. The sort descriptor used in the request groups objects into sections.
    public let fetchRequest: RequestType
    
    /// The persistent store connector instance the controller uses to execute a fetch request against.
    public let persistentStoreConnector: FetchedResultsStoreConnector<RequestType, ResultType>
    
    /// The keyPath on the fetched objects used to determine the section they belong to.
    public let sectionNameKeyPath: String?
    
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
    public init(fetchRequest: RequestType, persistentStoreConnector: FetchedResultsStoreConnector<RequestType, ResultType>, sectionNameKeyPath: String?) {
        self.fetchRequest = fetchRequest
        self.persistentStoreConnector = persistentStoreConnector
        self.sectionNameKeyPath = sectionNameKeyPath
    }
    
    /// Executes the fetch request.
    public func performFetch() {
        // TODO: Test if we should send a delegate callback at this point to allow a UITableView to clear our its contents?
        currentFetchHandle += 1
        
        // since we're starting a new fetch we'll wipe out our current
        // results and start fresh with an empty fetched results object
        currentFetchedResults = FetchedResults(
            predicate: fetchRequest.predicate,
            sortDescriptors: fetchRequest.sortDescriptors,
            sectionNameKeyPath: sectionNameKeyPath)
        
        // notify delegate
        delegate.controllerWillChangeContent?(self)
        
        // configure batch controller callbacks
        persistentStoreConnector.batchController.delegate.controllerWillBeginBatchingChanges = { [unowned self] (controller) in
            self.delegate.controllerWillChangeContent?(self)
        }
        
        persistentStoreConnector.batchController.delegate.controllerDidFinishBatchingChanges = { [unowned self] (controller, inserted, changed, deleted) in
            // keep track of the current results (before applying the changes)
            let oldFetchedResults: FetchedResults<ResultType>! = self.currentFetchedResults
            
            // starting from the current resuts, apply the changes to a new fetched results
            // object; note that force unwraping the current fetched results here is safe
            // since we've creating it at the start of the `performFetch()` method
            let newFetchedResults = FetchedResults(fetchedResults: self.currentFetchedResults!)
            newFetchedResults.apply(inserted: Array(inserted), changed: Array(changed), deleted: Array(deleted))
            
            // update the current results
            self.currentFetchedResults = newFetchedResults
            
            // compute the difference if the change tracker is configured
            if let controllerDidChangeResults = self.changeTracker.controllerDidChangeResults {
                // compute the difference
                let diff = FetchedResultsDifference(from: oldFetchedResults, to: newFetchedResults, changedObjects: Array(changed))
                controllerDidChangeResults(self, diff)
            }
            
            // notify the delegate
            self.delegate.controllerDidChangeContent?(self)
        }
        
        // execute the fetch
        persistentStoreConnector.execute(fetchRequest)
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
        if let d = currentFetchedResults?.description {
            return d
        }
        return "No fetched results. You must call `performFetch()`."
    }
}

public class FetchedResultsControllerDelegate<RequestType: FetchedResultsStoreRequest, ResultType: FetchedResultsStoreRequest.Result> {
    /// Called when the results controller begins receiving changes.
    public var controllerWillChangeContent: ((FetchedResultsController<RequestType, ResultType>) -> Void)?
    
    /// Called when the controller has completed processing the all changes.
    public var controllerDidChangeContent: ((FetchedResultsController<RequestType, ResultType>) -> Void)?
}

public class FetchedResultsControllerChangeTracking<RequestType: FetchedResultsStoreRequest, ResultType: FetchedResultsStoreRequest.Result> {
    /// Notifies the change tracker that the controller has changed its results.
    ///
    /// The change between the previous and new states is provided as a difference object.
    public var controllerDidChangeResults: ((_ controller: FetchedResultsController<RequestType, ResultType>, _ difference: FetchedResultsDifference<ResultType>) -> Void)?
}
