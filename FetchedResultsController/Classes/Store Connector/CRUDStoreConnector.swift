//
//  CRUDStoreConnector.swift
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

import FetchedResultsController

/// CRUDStoreConnector is an abstract superclass that adds insert, update, and delete methods
/// to the base store connector.
///
/// This class is provided for convenience. Given that the base store connector should already understand the
/// particulars of fetching data from the underlying store (i.e. `func execute(_ request: RequestType)`),
/// it follows that if one wanted to also perform CRUD operations on that same store (or specific location in that store)
/// this would be the logical place to do it.
///
/// - Note: The results controller does not call any of these methods itself.
open class CRUDStoreConnector<RequestType: FetchedResultsStoreRequest, ResultType: FetchedResultsStoreRequest.Result>: FetchedResultsStoreConnector<RequestType, ResultType> {
    // MARK: - CRUD
    /// Inserts the object into the underlying store.
    open func insert(_ obj: ResultType) {
        
    }
    
    /// Updates the object in the underlying store.
    open func update(_ obj: ResultType) {
        
    }
    
    /// Deletes the object from the underlying store.
    open func delete(_ obj: ResultType) {
        
    }
}
