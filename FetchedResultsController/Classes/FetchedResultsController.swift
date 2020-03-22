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

public class FetchedResultsControllerDelegate<FetchRequestType: FetchRequest, ResultType: FetchRequestResult> {
    /// Called when the results controller begins receiving changes.
    public var controllerWillChangeContent: ((FetchedResultsController<FetchRequestType, ResultType>) -> Void)?
    
    /// Called when the controller has completed processing the all changes.
    public var controllerDidChangeContent: ((FetchedResultsController<FetchRequestType, ResultType>) -> Void)?
}

public class FetchedResultsController<FetchRequestType: FetchRequest, ResultType: FetchRequestResult> {
    /// The data store the controller uses to fetch data.
    public let dataStore: DataStore<FetchRequestType, ResultType>
    
    /// The FirebaseFetchRequest instance used to do the fetching. The sort descriptor used in the request groups objects into sections.
    public let fetchRequest: FetchRequestType
    
    /// The keyPath on the fetched objects used to determine the section they belong to.
    public let sectionNameKeyPath: String?
    
    /// The results of the fetch. Returns `nil` if `performFetch()` hasn't yet been called.
    public var fetchedObjects: [ResultType] { return currentFetchedResults.results }

    /// The sections for the receiver’s fetch results.
    public var sections: [FetchedResultsSection<ResultType>] { return currentFetchedResults.sections }
    
    /// The delegate handling all the results controller delegate callbacks.
    public var delegate = FetchedResultsControllerDelegate<FetchRequestType, ResultType>()
    
    
    // MARK: - Private Properties
    /// The current fetched results.
    private var currentFetchedResults: FetchedResults<ResultType>!
    
    
    // MARK: - Lifecycle
    /// Returns a fetch request controller initialized using the given arguments.
    public init(dataStore: DataStore<FetchRequestType, ResultType>, fetchRequest: FetchRequestType, sectionNameKeyPath: String?) {
        self.dataStore = dataStore
        self.fetchRequest = fetchRequest
        self.sectionNameKeyPath = sectionNameKeyPath
    }
    
    /// Executes the fetch request.
    public func performFetch() {
        // create the empty fetched results object
        self.currentFetchedResults = FetchedResults(fetchRequest: self.fetchRequest, sectionNameKeyPath: self.sectionNameKeyPath)
        
        self.delegate.controllerWillChangeContent?(self)
        
        // execute the fetch
        dataStore.execute(fetchRequest) { [unowned self] (results) in
            // create a copy of the current fetch results
            let pendingFetchedResult = FetchedResults(fetchedResults: self.currentFetchedResults)
            
            // apply the changes to the pending results
            pendingFetchedResult.apply(inserted: results, updated: [], deleted: [])
            
            // apply the new results
            self.currentFetchedResults = pendingFetchedResult
            
            // notify the delegate
            self.delegate.controllerDidChangeContent?(self)
        }
    }
    
    
}
