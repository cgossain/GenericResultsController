//
//  FetchedResultsConfiguration.swift
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

/// Configuration parameters for managing fetched results.
///
/// - Note: The filter and sort closures are provided for convenience and are run locally after data has
///         been fetched. For efficiency it would be better to try and filter (and possibly sort) when fetching
///         data in your store connector implementation.
public struct FetchedResultsConfiguration<ResultType: StoreResult> {
    /// A block that is run against fetched objects used to determine the section they belong to.
    public var sectionNameProvider: ((ResultType) -> String?)?
    
    /// A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be included in the returned array.
    public var isIncluded: ((ResultType) -> Bool)?
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    public var areInIncreasingOrder: ((ResultType, ResultType) -> Bool)?
    
    /// Returns a results configuration initialized using the given arguments.
    public init(sectionNameProvider: ((ResultType) -> String?)? = nil,
                isIncluded: ((ResultType) -> Bool)? = nil,
                areInIncreasingOrder: ((ResultType, ResultType) -> Bool)? = nil) {
        self.sectionNameProvider = sectionNameProvider
        self.isIncluded = isIncluded
        self.areInIncreasingOrder = areInIncreasingOrder
    }
}


