//
//  FetchedResultsControllerDelegate.swift
//  FetchedResultsController
//
//  Created by Christian Gossain on 2021-01-13.
//

import Foundation

public class FetchedResultsControllerDelegate<RequestType: FetchedResultsStoreRequest, ResultType: FetchedResultsStoreRequest.Result> {
    public typealias Handler = (FetchedResultsController<RequestType, ResultType>) -> Void
    
    /// Called when the controller has completed processing the all changes.
    public var controllerDidChangeContent: Handler?
    
    /// Called when the results controller begins receiving changes.
    public var controllerWillChangeContent: Handler?
}
