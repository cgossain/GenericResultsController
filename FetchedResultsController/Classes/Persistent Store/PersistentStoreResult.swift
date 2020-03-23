//
//  PersistentStoreResult.swift
//  FetchedResultsController
//
//  Created by Christian Gossain on 2020-03-22.
//

import Foundation

/// A type that fetched objects must conform to.
public typealias FetchRequestResult = NSObject & IdentifiableFetchRequestResult

/// A class of types whose instances hold the value of an entity with stable identity.
///
/// This is similar to iOS 13's `Identifiable` protocol.
public protocol IdentifiableFetchRequestResult {
    /// The stable identity of the entity associated with `self`.
    var objectID: String { get }
}


