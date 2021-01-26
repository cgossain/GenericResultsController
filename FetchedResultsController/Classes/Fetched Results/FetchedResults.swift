//
//  FetchedResults.swift
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

let nilSectionName = "" // the name of the `nil` section

/// FetchedResults manages the entire set of results of a fetched results controller.
class FetchedResults<ResultType: FetchedResultsStoreRequest.Result> {
    /// The predicate to use to filter fetched results.
    let predicate: NSPredicate?
    
    /// The array of sort descriptors to use to sort fetched results in each section.
    let sortDescriptors: [NSSortDescriptor]?
    
    /// The keyPath on the fetched objects used to determine the section they belong to.
    let sectionNameKeyPath: String?
    
    /// The current fetch results ordered by section first (if a `sectionNameKeyPath` was provided), then by the fetch request sort descriptors.
    private(set) var results: [ResultType] = []
    
    /// An array containing the name of each section that exists in the results. The order of the items in this list represent the order that the sections should appear.
    ///
    /// - note: If the `sectionNameKeyPath` value is `nil`, a single section will be generated.
    var sectionKeyValues: [String] { return Array(sections.map({ $0.sectionKeyValue })) }
    
    /// The fetch results as arranged sections.
    var sections: [FetchedResultsSection<ResultType>] {
        if let sections = _sections {
            return sections
        }
        
        // compute the sections array
        let computed = Array(sectionsBySectionKeyValue.values).sorted(by: { $0.sectionKeyValue < $1.sectionKeyValue })
        _sections = computed
        return computed
    }
    private var _sections: [FetchedResultsSection<ResultType>]? // hold the current non-stale sections array
    
    /// A dictionary that maps a section to its `sectionKeyValue`.
    private var sectionsBySectionKeyValue: [String: FetchedResultsSection<ResultType>] = [:]
    
    /// A dictionary that maps a sections' index to its `sectionKeyValue`.
    private var sectionIndicesBySectionKeyValue: [String: Int] = [:]
    
    /// A dictionary that maps the sections' offset (i.e. first index of the section in the overall `results` array) to its `sectionKeyValue`.
    private var sectionOffsetsBySectionKeyValue: [String: Int] = [:]
    
    /// Specifies all the sort descriptors that should be used when inserting snapshots (including the `sectionNameKeyPath`).
    private var fetchSortDescriptors: [NSSortDescriptor] {
        var descriptors = [NSSortDescriptor]()
        
        // first sort by sections
        if let sectionNameKeyPath = sectionNameKeyPath {
            descriptors.append(NSSortDescriptor(key: sectionNameKeyPath, ascending: true))
        }
        
        // then by custom sort descriptors
        if let sortDescriptors = sortDescriptors {
            descriptors.append(contentsOf: sortDescriptors)
        }
        
        return descriptors
    }
    
    
    // MARK: - Lifecycle
    /// Initializes a new fetched results objects with the given arguments.
    ///
    /// - parameters:
    ///   - predicate: The predicate specified on a fetched results store request.
    ///   - sortDescriptors: The sort descriptors specified on a fetched results store request.
    ///   - sectionNameKeyPath: The key path on result objects that represents the section name.
    ///   - fetchedResults: The fetch result whose contents should be added to the receiver.
    init(predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]?, sectionNameKeyPath: String?, fetchedResults: FetchedResults? = nil) {
        self.predicate = predicate?.copy() as? NSPredicate
        self.sortDescriptors = sortDescriptors?.compactMap({ $0.copy() as? NSSortDescriptor })
        self.sectionNameKeyPath = sectionNameKeyPath
        
        // configure the initial state with the contents of a previous fetch result if provided
        if let fetchedResults = fetchedResults {
            // since this fetched results object might still change we'll want to make a copy of
            // its internal structures; we can keep referencing the same objects but the results
            // and sections need to be copied
            
            // append the result objects
            results.append(contentsOf: fetchedResults.results)
            
            // add new result section instances
            for (sectionKeyValue, resultsSection) in fetchedResults.sectionsBySectionKeyValue {
                let newResultsSection = FetchedResultsSection<ResultType>(
                    sectionKeyValue: resultsSection.sectionKeyValue,
                    sortDescriptors: resultsSection.sortDescriptors,
                    objects: resultsSection.objects)
                
                sectionsBySectionKeyValue[sectionKeyValue] = newResultsSection
            }
        }
    }
    
    /// Initializes a new fetched results objects using the contents of an existing fetched results objects.
    convenience init(fetchedResults: FetchedResults) {
        self.init(
            predicate: fetchedResults.predicate,
            sortDescriptors: fetchedResults.sortDescriptors,
            sectionNameKeyPath: fetchedResults.sectionNameKeyPath,
            fetchedResults: fetchedResults)
    }
}

extension FetchedResults {
    /// Returns the indexPath of the given object; otherwise returns `nil` if not found.
    public func indexPath(for obj: ResultType) -> IndexPath? {
        for (sectionIdx, section) in sections.enumerated() {
            guard let rowIdx = section.index(of: obj) else {
                continue
            }
            return IndexPath(row: rowIdx, section: sectionIdx)
        }
        return nil
    }
}

extension FetchedResults {
    /// Applies the given changes to the current results.
    func apply(inserted: [ResultType], changed: [ResultType], deleted: [ResultType]) {
        // apply inserted
        for obj in inserted {
            insert(obj: obj)
        }
        
        // apply changed
        for obj in changed {
            update(obj: obj)
        }
        
        // apply deleted
        for obj in deleted {
            delete(obj: obj)
        }
        
        // reset internal state since the contents have changed
        _sections = nil
        sectionIndicesBySectionKeyValue.removeAll()
        sectionOffsetsBySectionKeyValue.removeAll()
    }
    
    /// Returns the section index the given object belongs to.
    func sectionIndex(for obj: ResultType) -> Int? {
        let sectionKeyValue = self.sectionKeyValue(for: obj)
        
        // return the already computed index if available
        if let idx = sectionIndicesBySectionKeyValue[sectionKeyValue] {
            return idx
        }
        
        // the index has not yet been computed for this section key, so lets
        // find it then store it to avoid redundant work the next time this
        // function is called
        guard let idx = sectionKeyValues.firstIndex(where: { $0 == sectionKeyValue }) else {
            return nil
        }
        
        // store the index for the section key before returning
        sectionIndicesBySectionKeyValue[sectionKeyValue] = idx
        return idx
    }
    
    /// Returns the index within the overall results array where the given objects section begins.
    func sectionOffset(for obj: ResultType) -> Int? {
        let sectionKeyValue = self.sectionKeyValue(for: obj)
        
        // return the already computed index if available
        if let idx = sectionOffsetsBySectionKeyValue[sectionKeyValue] {
            return idx
        }
        
        // the offset has not yet been computed for this section key, so lets
        // find it then store it to avoid redundant work the next time this
        // function is called
        guard let idx = results.firstIndex(where: { self.sectionKeyValue(for: $0) == sectionKeyValue }) else {
            return nil
        }
        
        // store the index for the section key before returning
        sectionOffsetsBySectionKeyValue[sectionKeyValue] = idx
        return idx
    }
}

extension FetchedResults {
    /// Inserts the given object to the results array at the position that respects
    /// the fetch requests sort order and predicate.
    private func insert(obj: ResultType) {
        // ignore this insertion if the object does not evaluate against our predicate
        if !canInclude(obj: obj) {
            return
        }
        
        // compute the insertion index that maintains the sort order
        let idx = results.insertionIndex(of: obj, using: fetchSortDescriptors)
        
        // insert at the insertion index
        results.insert(obj, at: idx)
        
        // create or update the section
        let sectionKeyValue = self.sectionKeyValue(for: obj)
        let section = sectionsBySectionKeyValue[sectionKeyValue] ?? FetchedResultsSection(sectionKeyValue: sectionKeyValue, sortDescriptors: sortDescriptors)
        section.insert(obj: obj)
        sectionsBySectionKeyValue[sectionKeyValue] = section
    }
    
    /// Replaces the current version of the object with the given one.
    private func update(obj new: ResultType) {
        // since this object has been updated we have to assume its `sectionKeyValue` may
        // have changed which means that in addition to the object being updated, its position
        // in the results array may also completely changed; we can reliably perform this
        // update by always removing the "old" version of the object from its current position
        // and insert back at its "updated" position; if the object postion is not affected, we'll
        // simply have removed and inserted the object at the same index which is equivalent to
        // an update
        
        // remove the "old" object
        guard let idx = results.firstIndex(where: { $0.id == new.id }) else {
            return
        }
        let old = results[idx]
        delete(obj: old)
        
        // insert the "new" object
        insert(obj: new)
    }
    
    /// Removes the object if it exists in the results.
    private func delete(obj: ResultType) {
        guard let idx = results.firstIndex(where: { $0.id == obj.id }) else {
            return
        }
        
        // remove the object
        results.remove(at: idx)
        
        // update or remove the section
        let sectionKeyValue = self.sectionKeyValue(for: obj)
        
        // the force unwrap is intentional here; we've validated that this object exists in
        // the `results` array at the start of this method, therefore we can safely assume
        // that its section must also have been created (lest there be something seriously
        // wrong with our implementation)
        let section = sectionsBySectionKeyValue[sectionKeyValue]!
        section.remove(obj: obj)
        
        // remove the section if there are no more objects in it
        if section.numberOfObjects < 1 {
            sectionsBySectionKeyValue[sectionKeyValue] = nil
        }
        else {
            sectionsBySectionKeyValue[sectionKeyValue] = section
        }
    }
}

extension FetchedResults {
    /// Indicates if the given object should be included in the data set.
    private func canInclude(obj: ResultType) -> Bool {
        guard let predicate = predicate else {
            return true // no filter
        }
        
        // filter through the predicate
        return predicate.evaluate(with: obj)
    }
    
    /// Returns the section key value for the given object.
    private func sectionKeyValue(for obj: ResultType) -> String {
        guard let sectionNameKeyPath = sectionNameKeyPath,
            let value = obj.value(forKeyPath: sectionNameKeyPath) else {
            return nilSectionName
        }
        
        return String(describing: value)
    }
}

extension FetchedResults: CustomStringConvertible {
    var description: String {
        var components: [String] = []
        let sectionSummaries = sections.map({ return "\($0.sectionKeyValue):\($0.numberOfObjects)" })
        components.append("\(sections.count) sections {Name:Count} \(sectionSummaries.joined(separator: ","))")
        return components.joined(separator: " ")
    }
}
