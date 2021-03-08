//
//  PageQuery.swift
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
import PromiseKit

public enum PageQueryError: Error {
    /// An indication that the query was already fulfilled.
    ///
    /// A page query can only be resolved once.
    case alreadyFulfilled
    
    /// An indication that the query was already rejected.
    ///
    /// A page query can only be resolved once.
    case alreadyRejected
}

/// A query that fetches and returns results for a single page.
public class PageQuery<ResultType: StoreResult, RequestType: StoreRequest>: BaseQuery<ResultType, RequestType> {
    /// An object that marks the stopping point for a query and the starting point for retrieving the remaining results.
    public struct Cursor {
        /// The fetch limit of the request.
        let fetchLimit: Int
        
        /// Indicates the position of the first item of the next page.
        var next: Any?
        
        /// The total available results in the data set. Calculated from the start of the next page to the end of the results set.
        var totalResults: Int?
    }
    
    /// The data cursor to use for continuing the search.
    public var cursor: PageQuery.Cursor?
    
    /// A block that is called when a matching results are inserted, updated, or deleted from the store.
    public let resultsHandler: (_ results: [ResultType]?, _ cursor: PageQuery.Cursor?, _ error: Error?) -> Void
    
    
    // MARK: - Private Properties
    
    /// Internal promise and seal used to resolve a promise.
    ///
    /// Using promise kit here as a clean way to prevent the query from being resolved multiple times.
    private let (promise, seal) = Promise<(results: [ResultType], cursor: PageQuery.Cursor?)>.pending()
    
    
    // MARK: - Lifecycle
    
    /// Instantiates and returns a query.
    public init(storeRequest: RequestType, resultsHandler: @escaping (_ results: [ResultType]?, _ cursor: PageQuery.Cursor?, _ error: Error?) -> Void) {
        self.resultsHandler = resultsHandler
        super.init(storeRequest: storeRequest)
        
        // call the results handler when the promise resolves
        self.promise.done { (result) in
            self.resultsHandler(result.results, result.cursor, nil)
        }.catch { (error) in
            self.resultsHandler(nil, nil, error)
        }
    }
    
}

extension PageQuery {
    // MARK: -  Resolving Page Query
    
    /// Resolves the query by fulfilling it with the given results and page cursor.
    ///
    /// - Parameters:
    ///     - results: The results for the fetched page.
    ///     - cursor: A `PageQuery.Cursor` object that indicates there are more results to fetch or nil if
    ///               the results parameter contains all of the remaining search results. Use the provided object
    ///               to initialize a new page query object when you are ready to retrieve the next batch of results.
    ///
    /// - Throws: `PageQueryError.alreadyFulfilled` if the promise already resolved.
    public func fulfill(results: [ResultType], cursor: PageQuery.Cursor?) throws {
        if promise.isFulfilled { throw PageQueryError.alreadyFulfilled }
        seal.fulfill((results, cursor))
    }
    
    /// Resolves the query by rejecting it with the given error.
    ///
    /// - Throws: `PageQueryError.alreadyRejected` if the promise already resolved.
    public func reject(error: Error) throws {
        if promise.isRejected { throw PageQueryError.alreadyRejected }
        seal.reject(error)
    }
}
