//
//  PersistentStoreRequest.swift
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

/// A type that fetched objects must conform to.
public typealias PersistentStoreRequestResult = Identifiable & Hashable

/// A type that defines criteria used to retrieve data from a persistent store.
///
/// - Important:
///     - The results controller makes a copy of the fetch request just before the fetch is executed. Therefore
///       you must implement `copy(with zone: NSZone? = nil)` to ensure that your request properly
///       copies its own properties on every fetch.
public protocol PersistentStoreRequest: NSCopying {
    associatedtype ResultType: PersistentStoreRequestResult
    
    /// The fetch limit of the fetch request.
    ///
    /// The fetch limit specifies the maximum number of objects that a request should return when executed.
    ///
    /// A value of 0 indicates no maximum limit.
    var fetchLimit: Int { get set }
    
    /// A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be included in the returned array.
    var isIncluded: ((ResultType) -> Bool)? { get set }
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    var areInIncreasingOrder: ((ResultType, ResultType) -> Bool)? { get set }
}
