//
//  DiffStep+Inserted.swift
//  FetchedResultsController
//
//  Created by Christian Gossain on 2020-03-23.
//

import Foundation
import Dwifft

/// Simplifies filtering.
extension DiffStep {
    var isInserted: Bool {
        switch self {
        case .insert(_, _):
            return true
        case .delete(_, _):
            return false
        }
    }
}
