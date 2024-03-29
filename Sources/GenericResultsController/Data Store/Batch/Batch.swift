//
//  Batch.swift
//
//  Copyright (c) 2023 Christian Gossain
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

/// A batch object groups a set of changes together such that they can be tracked as a single block of changes.
///
/// You keep enqueuing changes into the batch and then eventually when done, you call the `flush()` method
/// to compute and return the deduplicated changes out of the batch.
public final class Batch<ResultType: DataStoreResult>: Identifiable {
    
    /// The dedpuplicated set of changes in the batch.
    public struct Digest {
        /// The deduplicated insertions.
        let inserted: [ResultType]
        
        /// The deduplicated updates.
        let updated: [ResultType]
        
        /// The deduplicated deletions.
        let deleted: [ResultType]
    }
    
    /// MARK: - Identifiable
    
    /// The batch ID.
    public let id: String
    
    // MARK: - Init
    
    /// Creates and returns a new batch object.
    public init(id: String) {
        self.id = id
    }
    
    // MARK: - API
    
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
        
        // deduplicate insertions
        for (insertedKey, _) in rawInserted {
            // if an object is inserted and deleted in the
            // same batch, the net effect is that nothing
            // actually happened and can therefore just
            // remove the object from the batch
            if rawDeleted[insertedKey] != nil {
                dedupedIns[insertedKey] = nil
                dedupedUpd[insertedKey] = nil
                dedupedDel[insertedKey] = nil
            }
            
            // if an object is inserted and updated in the
            // same batch, the net effect is that the newer
            // version was inserted; let's move the updated
            // version to our insertions set
            if let updatedObj = dedupedUpd[insertedKey] {
                dedupedIns[insertedKey] = updatedObj
                dedupedUpd[insertedKey] = nil
            }
        }
        
        // deduplicate updates
        for (updatedKey, _) in rawUpdated {
            // if an object is update and deleted in the
            // same batch, the net effect is that we've
            // deleted the object and therfore is no
            // point is reporting the update; let's
            // remove it from the updated set
            if rawDeleted[updatedKey] != nil {
                dedupedUpd[updatedKey] = nil
            }
        }
        
        // return the deduplicated batch
        return Digest(inserted: Array(dedupedIns.values), updated: Array(dedupedUpd.values), deleted: Array(dedupedDel.values))
    }
    
    /// Clears all tracked changes from the batch.
    public func reset() {
        rawInserted.removeAll()
        rawUpdated.removeAll()
        rawDeleted.removeAll()
    }
    
    // MARK: - Private
    
    private var rawInserted: [AnyHashable: ResultType] = [:]
    private var rawUpdated: [AnyHashable: ResultType] = [:]
    private var rawDeleted: [AnyHashable: ResultType] = [:]
}
