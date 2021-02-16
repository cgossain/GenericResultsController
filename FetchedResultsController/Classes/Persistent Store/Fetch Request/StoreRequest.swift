//
//  StoreRequest.swift
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
public typealias StoreRequestResult = Identifiable & Hashable

/// StoreRequest provides the basic structure of for a fetch request that can be
/// executed against a StoreConnector.
///
/// Just like in Core Data, it provides a description of search criteria used to retrieve data from a persistent store.
///
/// The idea is that this fetch request is executed against a concrete instance of a store connector,
/// therefore you can subclass this to create a more specific fetch request with additional paramters
/// that your store connector understands.
///
/// - Subclassing Notes:
///     - The results controller makes a copy of the fetch request just before the fetch is executed. So you are
///       required to override `copy(with zone: NSZone? = nil)` to make sure your subclass is properly
///       copied when performing a fetch.
public protocol StoreRequest: NSCopying {
    associatedtype ResultType: StoreRequestResult
    
    /// The fetch limit of the fetch request.
    ///
    /// The fetch limit specifies the maximum number of objects that a request should return when executed.
    ///
    /// A value of 0 indicates no maximum limit.
    var fetchLimit: Int { get }
    
    /// A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be included in the returned array.
    var isIncluded: ((ResultType) -> Bool)? { get }
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    var areInIncreasingOrder: ((ResultType, ResultType) -> Bool)? { get }
}

//extension NSCopying where Self : StoreRequest {
//    // MARK: - NSCopying
//
//    public func copy(with zone: NSZone? = nil) -> Any {
//        let copy = type(of: self).init()
//        copy.fetchLimit = fetchLimit
//        copy.isIncluded = isIncluded
//        copy.areInIncreasingOrder = areInIncreasingOrder
//        return copy
//    }
//}
