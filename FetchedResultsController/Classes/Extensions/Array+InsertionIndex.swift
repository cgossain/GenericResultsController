//
//  Array+InsertionIndex.swift
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

extension Array where Element: FetchRequestResult {
    /// Returns the index at which you should insert the snapshot in order to maintain a
    /// sorted array (according to the given sort descriptors).
    func insertionIndex(of element: Element, using sortDescriptors: [NSSortDescriptor]?) -> Int {
        return self.insertionIndex(of: element) {
            var result: ComparisonResult = .orderedSame
            if let sortDescriptors = sortDescriptors {
                for sortDescriptor in sortDescriptors {
                    result = sortDescriptor.compare($0, to: $1)
                    if result != .orderedSame {
                        break
                    }
                }
            }
            return (result == .orderedAscending)
        }
    }
}

extension Array {
    /// From Stack Overflow:
    /// http://stackoverflow.com/questions/26678362/how-do-i-insert-an-element-at-the-correct-position-into-a-sorted-array-in-swift
    ///
    /// Using binary search, finds the index at which a given element should be inserted into an
    /// already sorted array (assumes the array is already sorted). This function behaves just
    /// like the NSArray method `-indexOfObject:inSortedRange:options:usingComparator:`
    ///
    /// - parameters:
    ///     - element: The object to insert.
    ///     - isOrderedBefore: A predicate that returns true if its first argument should be
    ///                        ordered before its second argument; otherwise, false.
    func insertionIndex(of element: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var low = 0
        var high = self.count - 1
        while low <= high {
            let mid = (low + high)/2
            if isOrderedBefore(self[mid], element) {
                low = mid + 1
            }
            else if isOrderedBefore(element, self[mid]) {
                high = mid - 1
            }
            else {
                return mid // found at position `mid`
            }
        }
        return low // not found, would be inserted at position `low`
    }
}
