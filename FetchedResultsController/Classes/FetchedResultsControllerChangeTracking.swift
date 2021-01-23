//
//  FetchedResultsControllerChangeTracking.swift
//  FetchedResultsController
//
//  Created by Christian Gossain on 2021-01-13.
//

import Foundation

public class FetchedResultsControllerChangeTracking<RequestType: FetchedResultsStoreRequest, ResultType: FetchedResultsStoreRequest.Result> {
    public typealias DidChangeResultsHandler = (_ controller: FetchedResultsController<RequestType, ResultType>, _ difference: FetchedResultsDifference<ResultType>) -> Void
    
    /// Notifies the change tracker that the controller has changed its results.
    ///
    /// The change between the previous and new states is provided as a difference object.
    public var controllerDidChangeResults: DidChangeResultsHandler?
}
