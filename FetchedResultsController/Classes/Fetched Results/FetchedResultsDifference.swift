//
//  FetchedResultsDifference.swift
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
import Dwifft

public enum ResultsChangeType: Int {
    case insert     = 1
    case delete     = 2
    case move       = 3
    case update     = 4
}

/// FetchedResultsDifference provides detailed information about the differences between two
/// fetched results objects.
///
/// This information is useful for updating UI that lists the contents of a fetched results, such as
/// the indexes of added, removed, updated, and rearranged objects.
public struct FetchedResultsDifference<RequestType: PersistentStoreRequest> {
    public struct Section {
        let idx: Int
        let section: FetchedResultsSection<RequestType.ResultType>
    }
    
    public struct Row {
        let indexPath: IndexPath
        let value: RequestType.ResultType
    }
    
    /// The fetched results before applying the changes.
    let fetchedResultsBeforeChanges: FetchedResults<RequestType>
    
    /// The fetched results after applying the changes.
    let fetchedResultsAfterChanges: FetchedResults<RequestType>
    
    /// The indexes of the removed sections, relative to the 'before' state.
    public private(set) var removedSections: [Section]?
    
    /// The index paths of the removed rows, relative to the 'before' state.
    public private(set) var removedRows: [Row]?

    /// The indexes of the inserted sections, relative to the 'before' state, after deletions have been applied.
    public private(set) var insertedSections: [Section]?
    
    /// The index paths of the inserted rows, relative to the 'before' state, after deletions have been applied.
    public private(set) var insertedRows: [Row]?
    
    /// The index paths of the moved rows.
    public private(set) var movedRows: [(from: Row, to: Row)]?
    
    /// The index paths of the changed rows, relative to the 'before' state.
    public private(set) var changedRows: [Row]?
    
    
    // MARK: - Lifecycle
    
    /// Creates a difference between two fetched results objects.
    ///
    /// - Parameters:
    ///     - from: The fetched results object with the state of objects before the change.
    ///     - to: The fetched results object with the state of objects after the change.
    ///     - changedObjects: The objects in the fetch result whose content has been changed.
    init(from: FetchedResults<RequestType>, to: FetchedResults<RequestType>, changedObjects: [RequestType.ResultType]) {
        fetchedResultsBeforeChanges = from
        fetchedResultsAfterChanges = to
        
        var mutableChangedObjects = changedObjects
        
        // compute the sections diff
        let sectionsDiff = Dwifft.diff(fetchedResultsBeforeChanges.sectionKeyValues, fetchedResultsAfterChanges.sectionKeyValues)
        
        // compute the rows diff
        let rowsDiff = Dwifft.diff(fetchedResultsBeforeChanges.results, fetchedResultsAfterChanges.results)
        
        // compute deleted sections
        self.removedSections = sectionsDiff.filter({ !$0.isInserted }).map({ Section(idx: $0.idx, section: fetchedResultsBeforeChanges.sections[$0.idx]) })
        
        // compute inserted sections
        self.insertedSections = sectionsDiff.filter({ $0.isInserted }).map({ Section(idx: $0.idx, section: fetchedResultsAfterChanges.sections[$0.idx]) })
        
        // prep to compute moved rows
        var deletions = rowsDiff.filter({ !$0.isInserted })
        var insertions = rowsDiff.filter({ $0.isInserted })
        var moves: [(from: DiffStep<RequestType.ResultType>, to: DiffStep<RequestType.ResultType>)] = []
        
        // A "move" is a special type of change. Specifically, it involves a row being removed from one location, and then being
        // inserted at a new location. The following 2 steps will extract moved row from the inserted and deleted lists.
        
        // 1. We first need to identify the moved rows by simply checking that a deleted row also shows up as an inserted row.
        for deletion in deletions {
            if let insertion = insertions.filter({ $0.value.id == deletion.value.id }).first {
                moves.append((from: deletion, to: insertion))
            }
        }
        
        // 2. Once we've identified our moved rows, we need to remove those rows from both the deletions and insertions lists so as not
        // to "double dip". In otherwords we are saying that we will interpret those specific insertions and deletions as moves.
        for move in moves {
            // remove the deletions that will be handled in the move
            if let idx = deletions.firstIndex(where: { $0.value.id == move.from.value.id }) {
                deletions.remove(at: idx)
            }
            
            // remove the insertion that will be handled in the move
            if let idx = insertions.firstIndex(where: { $0.value.id == move.to.value.id }) {
                insertions.remove(at: idx)
            }
        }
        
        // compute inserted rows
        var insertedRows: [Row] = []
        for inserted in insertions {
            // convert the overall index to the appropriate section
            guard let sectionIdx = fetchedResultsAfterChanges.sectionIndex(for: inserted.value) else {
                continue
            }
            
            guard let sectionOffset = fetchedResultsAfterChanges.sectionOffset(for: inserted.value) else {
                continue
            }
            
            // calculate the index path
            let rowIdx = inserted.idx - sectionOffset
            let indexPath = IndexPath(row: rowIdx, section: sectionIdx)
            
            // track the insert
            insertedRows.append(Row(indexPath: indexPath, value: inserted.value))
        }
        self.insertedRows = insertedRows
        
        // compute deleted rows
        var removedRows: [Row] = []
        for removed in deletions {
            // convert the overall index to the appropriate section
            guard let sectionIdx = fetchedResultsBeforeChanges.sectionIndex(for: removed.value) else {
                continue
            }
            
            guard let sectionOffset = fetchedResultsBeforeChanges.sectionOffset(for: removed.value) else {
                continue
            }
            
            // calculate the index path
            let rowIdx = removed.idx - sectionOffset
            let indexPath = IndexPath(row: rowIdx, section: sectionIdx)
            
            // track the deletion
            removedRows.append(Row(indexPath: indexPath, value: removed.value))
        }
        self.removedRows = removedRows
        
        // compute moved rows
        var movedRows: [(from: Row, to: Row)] = []
        for move in moves {
            guard let fromSectionIdx = fetchedResultsBeforeChanges.sectionIndex(for: move.from.value) else {
                continue
            }
            
            guard let fromSectionOffset = fetchedResultsBeforeChanges.sectionOffset(for: move.from.value) else {
                continue
            }
            
            guard let toSectionIdx = fetchedResultsAfterChanges.sectionIndex(for: move.to.value) else {
                continue
            }
            
            guard let toSectionOffset = fetchedResultsAfterChanges.sectionOffset(for: move.to.value) else {
                continue
            }
            
            // calculate the `from` index path
            let fromRowIdx = move.from.idx - fromSectionOffset
            let fromPath = IndexPath(row: fromRowIdx, section: fromSectionIdx)
            
            // calculate the `to` index path
            let toRowIdx = move.to.idx - toSectionOffset
            let toPath = IndexPath(row: toRowIdx, section: toSectionIdx)
            
            // track the moved row
            movedRows.append((from: Row(indexPath: fromPath, value: move.from.value), to: Row(indexPath: toPath, value: move.to.value)))
            
            // remove moved objects from the changed objects list, this ensures it does not get tracked as a change as well
            if let idx = mutableChangedObjects.firstIndex(of: move.to.value) {
                mutableChangedObjects.remove(at: idx)
            }
        }
        self.movedRows = movedRows
        
        // compute changed/updated rows
        var changedRows: [Row] = []
        for changed in mutableChangedObjects {
            guard let path = fetchedResultsBeforeChanges.indexPath(for: changed) else {
                continue
            }
            
            changedRows.append(Row(indexPath: path, value: changed))
        }
        self.changedRows = changedRows
    }
}

extension FetchedResultsDifference {
    /// Convenience method that enumerates all the section changes described by the difference object.
    public func enumerateSectionChanges(_ body: ((_ section: FetchedResultsSection<RequestType.ResultType>, _ sectionIndex: Int, _ type: ResultsChangeType) -> Void)) {
        // removed sections
        if let removedSections = removedSections {
            for section in removedSections {
                body(section.section, section.idx, .delete)
            }
        }
        
        // inserted sections
        if let insertedSections = insertedSections {
            for section in insertedSections {
                body(section.section, section.idx, .insert)
            }
        }
    }
    
    /// Convenience method that enumerates all the row changes described by the difference object.
    public func enumerateRowChanges(_ body: ((_ anObject: RequestType.ResultType, _ indexPath: IndexPath?, _ type: ResultsChangeType, _ newIndexPath: IndexPath?) -> Void)) {
        // changed rows
        if let changedRows = changedRows {
            for row in changedRows {
                body(row.value, row.indexPath, .update, nil)
            }
        }
        
        // removed rows
        if let removedRows = removedRows {
            for row in removedRows {
                body(row.value, row.indexPath, .delete, nil)
            }
        }
        
        // inserted rows
        if let insertedRows = insertedRows {
            for row in insertedRows {
                body(row.value, nil, .insert, row.indexPath)
            }
        }
        
        // moved rows
        if let movedRows = movedRows {
            for move in movedRows {
                body(move.to.value, move.from.indexPath, .move, move.to.indexPath)
            }
        }
    }
}

extension FetchedResultsDifference: CustomStringConvertible {
    public var description: String {
        var components: [String] = []
        
        // TODO: DESCRIBE ROW OPS BY SECTION
        
        // SECTION INSERTION/REMOVAL
        // S{SECTION_IDX:IN:SECTION_NAME:SECTION_COUNT} // e.g. S{2:IN:Breakfast:5} - Section inserted at index 2 with section named "Breakfast" and with 5 items
        // S{SECTION_IDX:RM:SECTION_NAME:SECTION_COUNT} // e.g. S{2:RM:Breakfast:5} - Section removed at index 2 with section named "Breakfast" and with 5 items
        
        // ROW INSERTION/REMOVAL (describe by section)
        // R{SECTION_IDX:IN:ROW_IDX} // e.g. R{2:IN:3} - Row in section section 2 was inserted at index 3
        // R{SECTION_IDX:RM:ROW_IDX} // e.g. R{2:RM:3} - Row in section section 2 was removed at index 3
        // R{SECTION_IDX:CH:ROW_IDX} // e.g. R{2:CH:3} - Row in section section 2 was changed at index 3
        // R{SECTION_IDX:MV:ROW_IDX:FROM<FROM_SEC:FROM_ROW>} // e.g. R{2:MV:3:FROM<2:5>} - Row moved into section 2 at index 3 from row 5 in section 2
        
        // describe inserted sections
        for s in insertedSections ?? [] {
            let desc = String(format: "S{%d:IN:%@:%d}", s.idx, s.section.name, s.section.numberOfObjects)
            components.append(desc)
        }
        
        // describe removed section
        for s in removedSections ?? [] {
            let desc = String(format: "S{%d:RM:%@:%d}", s.idx, s.section.name, s.section.numberOfObjects)
            components.append(desc)
        }
        
        // describe inserted rows
        for r in insertedRows ?? [] {
            let desc = String(format: "R{%d:IN:%d}", r.indexPath.section, r.indexPath.row)
            components.append(desc)
        }
        
        // describe removed rows
        for r in removedRows ?? [] {
            let desc = String(format: "R{%d:RM:%d}", r.indexPath.section, r.indexPath.row)
            components.append(desc)
        }
        
        // describe changed rows
        for r in changedRows ?? [] {
            let desc = String(format: "R{%d:CH:%d}", r.indexPath.section, r.indexPath.row)
            components.append(desc)
        }
        
        // describe moved rows
        for r in movedRows ?? [] {
            let desc = String(format: "R{%d:MV:%d:FROM<%d:%d>}", r.to.indexPath.section, r.to.indexPath.row, r.from.indexPath.section, r.from.indexPath.row)
            components.append(desc)
        }
        
        return components.joined(separator: ",")
    }
}
