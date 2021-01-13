//
//  FetchedResultsControllerError.swift
//  FetchedResultsController
//
//  Created by Christian Gossain on 2021-01-13.
//

import Foundation

public enum FetchedResultsControllerError: Error {
    case invalidIndexPath(row: Int, section: Int)
}
