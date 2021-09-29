//
//  Results.swift
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

/// A results object manages the entire set of results for a results controller instance.
class Results<ResultType: DataStoreResult, RequestType: StoreRequest> {
    /// The search criteria used to retrieve data from a persistent store.
    let storeRequest: RequestType
    
    /// The results configuration.
    let resultsConfiguration: GenericResultsControllerConfiguration<ResultType>?
    
    /// The entire set of result objects ordered by section first (if a `sectionNameProvider` was specifed in the configuration), then by the `areInIncreasingOrder` predicate (if specified in the configuration).
    private(set) var results: [ResultType] = []
    
    /// An array containing the name of each section that exists in the results set.
    ///
    /// The order of the items in this list represent the order that the sections should appear in your UI.
    ///
    /// - Note: If a `sectionNameProvider` was not specified in the configuration, a single section will be generated.
    var sectionKeyValues: [String] { return Array(sections.map({ $0.sectionKeyValue })) }
    
    /// The fetch results as arranged sections.
    var sections: [ResultsSection<ResultType>] {
        if let sections = _sections {
            return sections
        }
        
        // compute the sections array
        let computed = sectionsBySectionKeyValue.values.sorted(by: {
            return self.sectionNamesAreInIncreasingOrder($0.sectionKeyValue, $1.sectionKeyValue)
        })
        _sections = computed
        return computed
    }
    
    
    // MARK: - Private Properties
    
    /// A dictionary that maps a section to its `sectionKeyValue`.
    private var sectionsBySectionKeyValue: [String: ResultsSection<ResultType>] = [:]
    
    /// A dictionary that maps a result objects `sectionKeyValue` to its ID.
    private var sectionKeyValuesByID: [AnyHashable: String] = [:]
    
    
    // MARK: - Private Properties (Computed)
    
    /// The computed sections array.
    private var _sections: [ResultsSection<ResultType>]? // hold the current non-stale sections array
    
    /// A dictionary that maps a sections' index to its `sectionKeyValue`.
    private var sectionIndicesBySectionKeyValue: [String: Int] = [:]
    
    /// A dictionary that maps the sections' offset (i.e. first index of the section in the overall `results` array) to its `sectionKeyValue`.
    private var sectionOffsetsBySectionKeyValue: [String: Int] = [:]
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    ///
    /// This is used to sort the sections.
    private var sectionNamesAreInIncreasingOrder: (String, String) -> Bool {
        guard let sectionNamesAreInIncreasingOrder = resultsConfiguration?.sectionNamesAreInIncreasingOrder else {
            return { $0 < $1 } // fallback to alphabetical ordering
        }
        return sectionNamesAreInIncreasingOrder
    }
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    ///
    /// This predicate is used to sort the entire set of fetched results. It first sorts by section name, then by the `areInIncreasingOrder` predicate if specified on the results configuration.
    private var fetchedResultsAreInIncreasingOrder: (ResultType, ResultType) -> Bool {
        return { (left, right) -> Bool in
            let leftSectionName = self.sectionName(for: left)
            let rightSectionName = self.sectionName(for: right)
            
            // 1. sort by section name
            if leftSectionName != rightSectionName {
                if self.sectionNamesAreInIncreasingOrder(leftSectionName, rightSectionName) {
                    return true
                }
                else {
                    return false
                }
            }
            
            // 2. sort within the section
            if let areInIncreasingOrder = self.resultsConfiguration?.areInIncreasingOrder {
                return areInIncreasingOrder(left, right)
            }
            
            // 3. fallback to true
            return true
        }
    }
    
    
    // MARK: - Lifecycle
    
    /// Creates and returns a new results objects.
    ///
    /// - Parameters:
    ///   - storeRequest: The search criteria used to retrieve data from a persistent store.
    ///   - resultsConfiguration: The results configuration.
    ///   - fetchedResults: The fetched results whose contents should be added to the receiver.
    init(
        storeRequest: RequestType,
        resultsConfiguration: GenericResultsControllerConfiguration<ResultType>?,
        fetchedResults: Results? = nil
    ) {
        self.storeRequest = storeRequest
        self.resultsConfiguration = resultsConfiguration
        
        // configure the initial state with the contents of a previous fetch result if provided
        if let fetchedResults = fetchedResults {
            // since this fetched results object might still change we'll want to make a copy of
            // its internal structures; we can keep referencing the same objects but the results
            // and sections need to be copied
            
            // append the result objects
            results.append(contentsOf: fetchedResults.results)
            
            // copy the result sections
            for (sectionKeyValue, resultsSection) in fetchedResults.sectionsBySectionKeyValue {
                let newResultsSection = ResultsSection<ResultType>(
                    sectionKeyValue: resultsSection.sectionKeyValue,
                    areInIncreasingOrder: resultsSection.areInIncreasingOrder,
                    objects: resultsSection.objects)
                
                sectionsBySectionKeyValue[sectionKeyValue] = newResultsSection
            }
            
            // copy the section key value mappings
            sectionKeyValuesByID = fetchedResults.sectionKeyValuesByID
        }
    }
    
    /// Creates and returns a new fetched results objects with the contents of an existing fetched results objects.
    convenience init(fetchedResults: Results) {
        self.init(storeRequest: fetchedResults.storeRequest,
                  resultsConfiguration: fetchedResults.resultsConfiguration,
                  fetchedResults: fetchedResults)
    }
    
    /// Returns the indexPath of the given object; otherwise returns `nil` if not found.
    func indexPath(for obj: ResultType) -> IndexPath? {
        for (sectionIdx, section) in sections.enumerated() {
            guard let rowIdx = section.index(of: obj) else { continue }
            return IndexPath(row: rowIdx, section: sectionIdx)
        }
        return nil
    }
}

extension Results {
    /// Applies the given changes to the current results.
    func apply(inserted ins: [ResultType]?, updated upd: [ResultType]?, deleted del: [ResultType]?) {
        // apply changes
        ins?.forEach({ insert(obj: $0) })
        upd?.forEach({ update(obj: $0) })
        del?.forEach({ delete(obj: $0) })
        
        // discard objects above the fetch limit;
        // note that it's expected the store connector
        // should be efficient and respect the fetch
        // limit, however this may not always be the case
        // therefore as a safeguard the following code
        // will discard any objects above the fetch limit
        if storeRequest.fetchLimit > 0, results.count > storeRequest.fetchLimit {
            let min = storeRequest.fetchLimit
            let max = results.count - 1
            let objectsToDiscard = results[min...max]
            for obj in objectsToDiscard {
                delete(obj: obj)
            }
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

extension Results {
    /// Inserts the given object to the results array at the position that respects
    /// the fetch requests sort order and predicate.
    private func insert(obj: ResultType) {
        // ignore this insertion if the object does not evaluate against our predicate
        if !canInclude(obj: obj) { return }
        
        // what if the object already exists in our result set? we can assume we're
        // inserting a newer version of the object, therefore we replace it
        if let idx = results.firstIndex(where: { $0.id == obj.id }) {
            let old = results[idx]
            delete(obj: old)
        }
        
        // compute the insertion index that maintains the sort order
        let idx = results.insertionIndex(of: obj, isOrderedBefore: self.fetchedResultsAreInIncreasingOrder)
        
        // insert at the insertion index
        results.insert(obj, at: idx)
        
        // create or update the section
        let sectionKeyValue = self.sectionName(for: obj)
        let section = sectionsBySectionKeyValue[sectionKeyValue] ?? ResultsSection(sectionKeyValue: sectionKeyValue, areInIncreasingOrder: resultsConfiguration?.areInIncreasingOrder)
        section.insert(obj: obj)
        sectionsBySectionKeyValue[sectionKeyValue] = section
        sectionKeyValuesByID[obj.id] = sectionKeyValue
    }
    
    /// Replaces the current version of the object with the given one.
    private func update(obj new: ResultType) {
        // since this object has been updated, we have to assume its `sectionKeyValue` may
        // have changed which means that, in addition to the object being updated, its position
        // in the results array may also completely changed; we can reliably perform this
        // update by always removing the "old" version of the object from its current position
        // and insert back at its "updated" position; if the object postion is not affected, we'll
        // simply have removed and inserted the object at the same index which is equivalent to
        // an update
        
        // delete the "old" version
        if let idx = results.firstIndex(where: { $0.id == new.id }) {
            let old = results[idx]
            delete(obj: old)
        }
        
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
        
        // clear the cached section name
        sectionKeyValuesByID[obj.id] = nil
    }
}

extension Results {
    /// Indicates if the given object should be included in the data set.
    private func canInclude(obj: ResultType) -> Bool {
        return resultsConfiguration?.isIncluded?(obj) ?? true
    }
    
    /// Returns the section key value for the given object.
    private func sectionName(for obj: ResultType) -> String {
        // return the cached section name if available
        if let cachedSectionName = sectionKeyValuesByID[obj.id] {
            return cachedSectionName
        }
        
        // get the section name from the provider
        if let sectionNameProvider = resultsConfiguration?.sectionNameProvider,
           let sectionName = sectionNameProvider(obj) {
            return sectionName
        }
        
        // fallback to the nil section name
        return nilSectionName
    }
}

extension Results: CustomStringConvertible {
    var description: String {
        var components: [String] = []
        let sectionSummaries = sections.map({ return "\($0.sectionKeyValue):\($0.numberOfObjects)" })
        components.append("\(sections.count) sections {Name:Count} \(sectionSummaries.joined(separator: ","))")
        return components.joined(separator: " ")
    }
}
