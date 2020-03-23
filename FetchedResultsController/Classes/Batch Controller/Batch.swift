//
//  Batch.swift
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
