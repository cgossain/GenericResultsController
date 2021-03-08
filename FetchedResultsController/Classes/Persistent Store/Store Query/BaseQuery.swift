//
//  BaseQuery.swift
//  FetchedResultsController
//
//  Created by Christian Gossain on 2021-03-05.
//

import Foundation


/// An abstract class for all the query classes..
open class BaseQuery<ResultType: StoreResult, RequestType: StoreRequest> {
    /// The search criteria used to retrieve data from a persistent store.
    public let storeRequest: RequestType
    
    
    // MARK: - Lifecycle
    
    /// Instantiates and returns a query.
    public init(storeRequest: RequestType) {
        self.storeRequest = storeRequest
    }
    
}

extension BaseQuery: Identifiable {}
