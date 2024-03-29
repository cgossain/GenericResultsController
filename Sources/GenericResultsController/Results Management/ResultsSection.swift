//
//  ResultsSection.swift
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

/// A results section manages the results for a single section of the entire results set.
public final class ResultsSection<ResultType: DataStoreResult> {
    /// Name of the section.
    public var name: String { return sectionKeyValue }
    
    /// Number of objects in section.
    public var numberOfObjects: Int { return objects.count }
    
    /// Returns the array of objects in the section.
    public private(set) var objects: [ResultType]
    
    // MARK: - Internal
    
    /// The section key value (e.g. the section name).
    let sectionKeyValue: String
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    let areInIncreasingOrder: ((ResultType, ResultType) -> Bool)?
    
    // MARK: - Init
    
    /// Creates and returns a new section object with the given section key value and sort predicate.
    ///
    /// - Parameters:
    ///     - sectionKeyValue: The section key value (e.g. the section name).
    ///     - areInIncreasingOrder: A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    ///     - objects: The initial set of objects in the new section. The objects are assumed to be sorted. For internal use.
    init(
        sectionKeyValue: String,
        areInIncreasingOrder: ((ResultType, ResultType) -> Bool)?,
        objects: [ResultType] = []
    ) {
        self.sectionKeyValue = sectionKeyValue
        self.areInIncreasingOrder = areInIncreasingOrder
        self.objects = objects
    }
    
    // MARK: - API
    
    /// Inserts the given object into the section and returns the index at which it was inserted.
    @discardableResult
    func insert(obj: ResultType) -> Int {
        let idx = objects.insertionIndex(of: obj) { self.areInIncreasingOrder?($0, $1) ?? true }
        objects.insert(obj, at: idx)
        return idx
    }
    
    /// Removes the given object from the section and returns the index from which it was removed.
    @discardableResult
    func remove(obj: ResultType) -> Int? {
        guard let idx = index(of: obj) else {
            return nil
        }
        objects.remove(at: idx)
        return idx
    }
    
    /// Returns the index of the snapshot in the section, or `nil` if it was not found.
    func index(of obj: ResultType) -> Int? {
        guard let idx = objects.firstIndex(where: { $0.id == obj.id }) else {
            return nil
        }
        return idx
    }
}

extension ResultsSection: Equatable, Hashable {
    public static func ==(lhs: ResultsSection, rhs: ResultsSection) -> Bool {
        return lhs.sectionKeyValue == rhs.sectionKeyValue
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(sectionKeyValue)
    }
}

extension ResultsSection: CustomStringConvertible {
    public var description: String {
        return "| Section: \(name), Count: \(numberOfObjects) |"
    }
}
