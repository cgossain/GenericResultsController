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

public class FetchedResultsControllerDelegate<RequestType: PersistentStoreRequest, ResultType: FetchRequestResult> {
    /// Called when the results controller begins receiving changes.
    public var controllerWillChangeContent: ((FetchedResultsController<RequestType, ResultType>) -> Void)?
    
    /// Called when the controller has completed processing the all changes.
    public var controllerDidChangeContent: ((FetchedResultsController<RequestType, ResultType>) -> Void)?
}

public class FetchedResultsController<RequestType: PersistentStoreRequest, ResultType: FetchRequestResult> {
    /// The fetch request instance used to do the fetching. The sort descriptor used in the request groups objects into sections.
    public let fetchRequest: RequestType
    
    /// The persistent store connector instance the controller uses to execute a fetch request against.
    public let persistentStoreConnector: PersistentStoreConnector<RequestType, ResultType>
    
    /// The keyPath on the fetched objects used to determine the section they belong to.
    public let sectionNameKeyPath: String?
    
    /// The results of the fetch. Returns `nil` if `performFetch()` hasn't yet been called.
    public var fetchedObjects: [ResultType] { return currentFetchedResults.results }

    /// The sections for the receiver’s fetch results.
    public var sections: [FetchedResultsSection<ResultType>] { return currentFetchedResults.sections }
    
    /// The delegate handling all the results controller delegate callbacks.
    public var delegate = FetchedResultsControllerDelegate<RequestType, ResultType>()
    
    
    // MARK: - Private Properties
    /// The current fetched results.
    private var currentFetchedResults: FetchedResults<ResultType>!
    
    /// This value is incremented each time `-execute` is called.
    ///
    /// When executing an asynchronous fetch, you can use this value to validate that the
    /// handle has not changed between when `-execute` is called and the asynchronous
    /// results are returned. If the handle has changed, you can discard the returned results.
    public private(set) var currentFetchHandle = 0
    
    
    // MARK: - Lifecycle
    /// Returns a fetch request controller initialized using the given arguments.
    public init(fetchRequest: RequestType, persistentStoreConnector: PersistentStoreConnector<RequestType, ResultType>, sectionNameKeyPath: String?) {
        self.fetchRequest = fetchRequest
        self.persistentStoreConnector = persistentStoreConnector
        self.sectionNameKeyPath = sectionNameKeyPath
    }
    
    /// Executes the fetch request.
    public func performFetch() {
        currentFetchHandle += 1
        
        // since we're starting a new fetch we'll wipe out our current
        // results and start fresh with an empty fetched results object
        self.currentFetchedResults = FetchedResults(
            predicate: fetchRequest.predicate,
            sortDescriptors: fetchRequest.sortDescriptors,
            sectionNameKeyPath: sectionNameKeyPath)
        
        // notify delegate
        self.delegate.controllerWillChangeContent?(self)
        
        // configure batch controller callbacks
        persistentStoreConnector.batchController.delegate.controllerWillBeginBatchingChanges = { [unowned self] (controller) in
            self.delegate.controllerWillChangeContent?(self)
        }
        
        persistentStoreConnector.batchController.delegate.controllerDidFinishBatchingChanges = { [unowned self] (controller, inserted, changed, deleted) in
            // create a copy of the current fetch results
            let pendingFetchedResult = FetchedResults(fetchedResults: self.currentFetchedResults)

            // apply the changes to the pending results
            pendingFetchedResult.apply(inserted: Array(inserted), changed: Array(changed), deleted: Array(deleted))

            // apply the new results
            self.currentFetchedResults = pendingFetchedResult

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
        return currentFetchedResults.indexPath(for: obj)
    }
}

extension FetchedResultsController: CustomStringConvertible {
    public var description: String {
        return currentFetchedResults.description
    }
}
