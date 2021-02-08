//
//  FetchRequest.swift
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
public typealias FetchRequestResult = Identifiable & Hashable

/// FetchRequest provides the basic structure of for a fetch request that can be
/// executed against a StoreConnector.
///
/// Just like in Core Data, it provides a description of search criteria used to retrieve data from a persistent store.
///
/// The idea is that this fetch request is executed against a concrete instance of a store connector,
/// therefore you can subclass this to create a more specific fetch request with additional paramters
/// that your store connector understands.
open class FetchRequest<ResultType: FetchRequestResult> {
    /// A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be included in the returned array.
    open var isIncluded: ((ResultType) -> Bool)?
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    open var areInIncreasingOrder: ((ResultType, ResultType) -> Bool)?
    
    /// Creates and initializes a new fetch request.
    public init() {}
}
