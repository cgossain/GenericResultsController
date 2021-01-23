//
//  FetchedResultsStoreRequest.swift
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

/// FetchedResultsStoreRequest provides the basic structure of for a fetch request that can be
/// executed against a FetchedResultsStoreConnector.
///
/// The idea is that this fetch request is executed against a concrete instance of a store connector,
/// therefore you can subclass this to create a more specific fetch request with additional paramters
/// that your store connector understands.
open class FetchedResultsStoreRequest {
    /// A type that fetched objects must conform to.
    ///
    /// - Note: Result objects need to subclass NSObject because the controller uses
    ///         key-value coding (i.e. `-value(forKeyPath:)`) to query result objects
    ///         for the section name, predicate key paths, and sort descriptor key paths.
    public typealias Result = NSObject & Identifiable
    
    /// A predicate used by the results controller to filter the query results.
    open var predicate: NSPredicate?
    
    /// An array of sort descriptors used by the results controller to sorts the fetched snapshots in each section.
    open var sortDescriptors: [NSSortDescriptor]?
    
    /// Initializes a new fetch request.
    public init() {
        
    }
}
