//
//  PersistentStoreRequest.swift
//  FetchedResultsController
//
//  Created by Christian Gossain on 2021-02-15.
//

import Foundation

/// A type that fetched objects must conform to.
public typealias PersistentStoreRequestResult = Identifiable & Hashable

/// A type that defines criteria used to retrieve data from a persistent store.
///
/// - Implementaion Notes:
///     - The results controller makes a copy of the fetch request just before the fetch is executed. Therefore
///       you must implement `copy(with zone: NSZone? = nil)` to make sure your request is
///       property copied when performing a fetch.
public protocol PersistentStoreRequest: NSCopying {
    associatedtype ResultType: PersistentStoreRequestResult
    
    /// The fetch limit of the fetch request.
    ///
    /// The fetch limit specifies the maximum number of objects that a request should return when executed.
    ///
    /// A value of 0 indicates no maximum limit.
    var fetchLimit: Int { get set }
    
    /// A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be included in the returned array.
    var isIncluded: ((ResultType) -> Bool)? { get set }
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    var areInIncreasingOrder: ((ResultType, ResultType) -> Bool)? { get set }
}
