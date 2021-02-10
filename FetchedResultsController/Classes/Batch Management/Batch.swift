//
//  Batch.swift
//
//  Copyright (c) 2021 Christian Gossain
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

/// A Batch groups a set of changes together such that they can be tracked as a single unit.
///
/// Call `flush()` to get the deduplicated changes out of the batch.
public final class Batch<ResultType: FetchRequestResult>: Identifiable {
    /// The dedpuplicated set of changes in the batch.
    public struct Digest {
        /// The deduplicated insertions.
        let inserted: Set<ResultType>
        
        /// The deduplicated updates.
        let updated: Set<ResultType>
        
        /// The deduplicated deletions.
        let deleted: Set<ResultType>
    }
    
    /// The batch ID.
    public let id: AnyHashable
    
    
    // MARK: - Private Properties
    
    /// The raw insertions.
    private var rawInserted: [AnyHashable: ResultType] = [:]
    
    /// The raw updates.
    private var rawUpdated: [AnyHashable: ResultType] = [:]
    
    /// The raw deletions.
    private var rawDeleted: [AnyHashable: ResultType] = [:]
    
    
    // MARK: - Lifecycle
    
    public init(id: AnyHashable) {
        self.id = id
    }
    
    /// Tracks the object as an insertion to the batch.
    public func insert(_ obj: ResultType) {
        // note that if the object already exists, it
        // will simply be replaced with its newer version
        rawInserted[obj.id] = obj
    }
    
    /// Tracks the object as an update to the batch.
    public func update(_ obj: ResultType) {
        // note that if the object already exists, it
        // will simply be replaced with its newer version
        rawUpdated[obj.id] = obj
    }
    
    /// Tracks the object as a deletion from the batch.
    public func delete(_ obj: ResultType) {
        // note that if the object already exists, it
        // will simply be replaced with its newer version
        rawDeleted[obj.id] = obj
    }
    
    /// Returns the dedpuplicated set of changes in the batch.
    public func flush() -> Batch.Digest {
        var dedupedIns = rawInserted
        var dedupedUpd = rawUpdated
        var dedupedDel = rawDeleted
        
        // deduplicate insersions
        for (insertedKey, _) in rawInserted {
            // if the inserted object is also deleted in the
            // same batch, these events cancel each other out
            // and the effective change is that "nothing hapenned" so
            // we can clear this object out of the batch entirely
            if rawDeleted[insertedKey] != nil {
                dedupedIns[insertedKey] = nil
                dedupedUpd[insertedKey] = nil
                dedupedDel[insertedKey] = nil
            }
            
            // if the inserted object is also updated in the
            // same batch, the effective change in the
            // batch is that "the newer version of the object
            // was inserted"
            if let updatedObj = dedupedUpd[insertedKey] {
                dedupedIns[insertedKey] = updatedObj
                dedupedUpd[insertedKey] = nil
            }
        }
        
        // deduplicate updates
        for (updatedKey, _) in rawUpdated {
            // if the updated object is also deleted in the
            // same batch, the effective change in the
            // batch is that "the object was deleted",
            // there's no point in reporting the update
            if rawDeleted[updatedKey] != nil {
                dedupedUpd[updatedKey] = nil
            }
        }
        
        // return the deduplicated batch
        return Digest(inserted: Set(dedupedIns.values), updated: Set(dedupedUpd.values), deleted: Set(dedupedDel.values))
    }
    
    /// Clears all tracked changes.
    public func reset() {
        rawInserted.removeAll()
        rawUpdated.removeAll()
        rawDeleted.removeAll()
    }
}
