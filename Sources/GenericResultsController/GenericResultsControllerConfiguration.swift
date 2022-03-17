//
//  GenericResultsControllerConfiguration.swift
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

/// The configuration parameters for managing fetched results.
///
/// - Note: The filter and sort closures are provided for convenience and are run locally after data has
///         been fetched. It would be more efficient to make every effort to utilize any filter and sort parameters
///         defined on your store request within your store connector implementation rather than leaning on the
///         controller to do this locally on a larger data set that you might fetch. That being said, if your data set
///         is small, you probably don't need to worry about this.
public struct GenericResultsControllerConfiguration<ResultType: DataStoreResult> {
    /// A block that is run against fetched objects used to determine the section they belong to.
    public var sectionNameProvider: ((ResultType) -> String?)?
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    ///
    /// By default, sections  are sorted alphabetically.
    public var sectionNamesAreInIncreasingOrder: ((String, String) -> Bool)?
    
    /// A closure that takes an element of the sequence as its argument and returns a Boolean value indicating whether the element should be included in the returned array.
    public var isIncluded: ((ResultType) -> Bool)?
    
    /// A predicate that returns true if its first argument should be ordered before its second argument; otherwise, false.
    public var areInIncreasingOrder: ((ResultType, ResultType) -> Bool)?
    
    /// Creates and returns a new empty results configuration.
    public init() {
        
    }
}


