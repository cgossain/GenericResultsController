//
//  GenericResultsControllerDelegate.swift
//
//  Copyright (c) 2022 Christian Gossain
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

/// A generic implementation of the results controller delegate.
///
/// In order to support generics, this protocol is defined as a class object with closure parameters rather than an actual Swift protocol.
public final class GenericResultsControllerDelegate<ResultType: DataStoreResult, RequestType: DataStoreRequest> {
    /// Returns the results configuration for the given store request.
    ///
    /// Called just before the query is executed.
    public var controllerResultsConfiguration: ((GenericResultsController<ResultType, RequestType>, RequestType) -> GenericResultsControllerConfiguration<ResultType>)?
    
    /// Called when the results controller begins receiving changes.
    public var controllerWillChangeContent: ((GenericResultsController<ResultType, RequestType>) -> Void)?
    
    /// Called when the controller has completed processing the all changes.
    public var controllerDidChangeContent: ((GenericResultsController<ResultType, RequestType>) -> Void)?
}
