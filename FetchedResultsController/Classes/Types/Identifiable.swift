//
//  Identifiable.swift
//  FetchedResultsController
//
//  Created by Christian Gossain on 2021-06-08.
//

import Foundation

public protocol Identifiable {
    /// The stable identity of the entity associated with this instance.
    var id: String { get }
}
