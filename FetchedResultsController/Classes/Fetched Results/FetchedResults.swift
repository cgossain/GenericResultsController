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

/// The name of the `nil` section
let nilSectionName = ""

/// FetchedResults manages the entire set of results of a fetched results controller.
class FetchedResults<ResultType: BaseResultObject> {
    /// A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be included in the returned array.
    let isIncluded: ((ResultType) -> Bool)?
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    let areInIncreasingOrder: ((ResultType, ResultType) -> Bool)?
    
    /// A block that is run against fetched objects used to determine the section they belong to.
    let sectionNameProvider: SectionNameProvider<ResultType>?
    
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
    
    // MARK: - Private Properties
    private var _sections: [FetchedResultsSection<ResultType>]? // hold the current non-stale sections array
    
    /// A dictionary that maps a section to its `sectionKeyValue`.
    private var sectionsBySectionKeyValue: [String: FetchedResultsSection<ResultType>] = [:]
    
    /// A dictionary that maps a sections' index to its `sectionKeyValue`.
    private var sectionIndicesBySectionKeyValue: [String: Int] = [:]
    
    /// A dictionary that maps the sections' offset (i.e. first index of the section in the overall `results` array) to its `sectionKeyValue`.
    private var sectionOffsetsBySectionKeyValue: [String: Int] = [:]
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    ///
    /// - Note: This predicate sorts against the section name as its primary key and then falls back to the section specifc sorting logic. It is intended to be used against the entire fetched results and not just a single section.
    private var fetchedResultsAreInIncreasingOrder: (ResultType, ResultType) -> Bool {
        return { (left, right) -> Bool in
            // 1. sort by sections first
            let leftSectionName = self.sectionName(for: left)
            let rightSectionName = self.sectionName(for: right)
            
            if leftSectionName < rightSectionName {
                return true
            }
            
            if leftSectionName > rightSectionName {
                return false
            }
            
            // 2. if section names are the same, sort using the section sorting logic
            if let areInIncreasingOrder = self.areInIncreasingOrder {
                return areInIncreasingOrder(left, right)
            }
            
            // 3. fallback to true if needed
            return true
        }
    }
    
    
    // MARK: - Lifecycle
    /// Initializes a new fetched results objects with the given arguments.
    ///
    /// - Parameters:
    ///   - isIncluded: A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be included in the returned array.
    ///   - areInIncreasingOrder: A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    ///   - sectionNameProvider: A block that is run against fetched objects used to determine the section they belong to.
    ///   - fetchedResults: The fetch result whose contents should be added to the receiver.
    init(isIncluded: ((ResultType) -> Bool)?,
         areInIncreasingOrder: ((ResultType, ResultType) -> Bool)?,
         sectionNameProvider: SectionNameProvider<ResultType>? = nil,
         fetchedResults: FetchedResults? = nil) {
        self.isIncluded = isIncluded
        self.areInIncreasingOrder = areInIncreasingOrder
        self.sectionNameProvider = sectionNameProvider
        
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
                    areInIncreasingOrder: resultsSection.areInIncreasingOrder,
                    objects: resultsSection.objects)
                
                sectionsBySectionKeyValue[sectionKeyValue] = newResultsSection
            }
        }
    }
    
    /// Initializes a new fetched results objects using the contents of an existing fetched results objects.
    convenience init(fetchedResults: FetchedResults) {
        self.init(
            isIncluded: fetchedResults.isIncluded,
            areInIncreasingOrder: fetchedResults.areInIncreasingOrder,
            sectionNameProvider: fetchedResults.sectionNameProvider,
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
        let sectionKeyValue = self.sectionName(for: obj)
        
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
        let sectionKeyValue = self.sectionName(for: obj)
        
        // return the already computed index if available
        if let idx = sectionOffsetsBySectionKeyValue[sectionKeyValue] {
            return idx
        }
        
        // the offset has not yet been computed for this section key, so lets
        // find it then store it to avoid redundant work the next time this
        // function is called
        guard let idx = results.firstIndex(where: { self.sectionName(for: $0) == sectionKeyValue }) else {
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
//        let idx = results.insertionIndex(of: obj, using: fetchSortDescriptors)
        let idx = results.insertionIndex(of: obj, isOrderedBefore: self.fetchedResultsAreInIncreasingOrder)
        
        // insert at the insertion index
        results.insert(obj, at: idx)
        
        // create or update the section
        let sectionKeyValue = self.sectionName(for: obj)
        let section = sectionsBySectionKeyValue[sectionKeyValue] ?? FetchedResultsSection(sectionKeyValue: sectionKeyValue, areInIncreasingOrder: areInIncreasingOrder)
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
        
        // delete the "old" version
        guard let idx = results.firstIndex(where: { $0.id == new.id }) else { return }
        let old = results[idx]
        delete(obj: old)
        
        // insert the "updated" version
        insert(obj: new)
    }
    
    /// Removes the object if it exists in the results.
    private func delete(obj: ResultType) {
        // remove the object
        guard let idx = results.firstIndex(where: { $0.id == obj.id }) else { return }
        results.remove(at: idx)
        
        // update or remove the section
        let sectionKeyValue = self.sectionName(for: obj)
        
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
        return self.isIncluded?(obj) ?? true
    }
    
    /// Returns the section key value for the given object.
    private func sectionName(for obj: ResultType) -> String {
        guard let sectionNameProvider = sectionNameProvider,
              let sectionName = sectionNameProvider(obj) else {
            return nilSectionName
        }
        
        return sectionName
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
