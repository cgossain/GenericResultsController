//
//  Batch.swift
//  FirebaseResultsController
//
//  Created by Christian Gossain on 2020-01-13.
//

import Foundation

/// A Batch object allows tracking and grouping a batch of changes together as a single unit.
class Batch<ResultType: FetchRequestResult> {
    struct Result {
        let inserted: [String: ResultType]
        let changed: [String: ResultType]
        let removed: [String: ResultType]
    }
    
    /// A unique identifier for this batch.
    let identifier = UUID().uuidString
    
    private var rawInserted: [String: ResultType] = [:]
    private var rawChanged: [String: ResultType] = [:]
    private var rawRemoved: [String: ResultType] = [:]
}

extension Batch {
    func insert(_ obj: ResultType) {
        // note that if the object already exists it will
        // simply be replaced with its newer version
        rawInserted[obj.objectID] = obj
    }
    
    func update(_ obj: ResultType) {
        // note that if the object already exists it will
        // simply be replaced with its newer version
        rawChanged[obj.objectID] = obj
    }
    
    func remove(_ obj: ResultType) {
        // note that if the object already exists it will
        // simply be replaced with its newer version
        rawRemoved[obj.objectID] = obj
    }
}

extension Batch {
    func flush() -> Batch.Result {
        // deduplicate
        var inserted = rawInserted
        var changed = rawChanged
        var removed = rawRemoved
        for (key, snapshot) in rawInserted {
            if rawChanged[key] != nil {
                // replace the existing `inserted` version with the `changed` version
                inserted[key] = snapshot
                
                // remove from the `changed` version
                changed[key] = nil
            }
            else if rawRemoved[key] != nil {
                // the same snapshot was both inserted and removed
                // in the same batch (i.e. no net change)
                inserted[key] = nil
                removed[key] = nil
            }
        }
        
        // return the deduplicated batch
        return Result(inserted: inserted, changed: changed, removed: removed)
    }
}
