//
//  Array+InsertionIndex.swift
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

extension Array {
    /// Using binary search, finds the index at which the given element should be inserted.
    ///
    /// This method behaves just like the NSArray method `-indexOfObject:inSortedRange:options:usingComparator:`.
    ///
    /// Stack Overflow:
    /// http://stackoverflow.com/questions/26678362/how-do-i-insert-an-element-at-the-correct-position-into-a-sorted-array-in-swift
    ///
    /// - Parameters:
    ///     - element: The object to insert.
    ///     - isOrderedBefore: A predicate that returns true if its first argument should
    ///                    be ordered before its second argument; otherwise, false.
    ///
    /// - Important: Your array must already be sorted for this method to work, this is simply because binary
    ///              search assumes you are inserting into an already sorted array.
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
