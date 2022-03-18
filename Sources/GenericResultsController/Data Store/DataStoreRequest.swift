//
//  DataStoreRequest.swift
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

/// A type that defines criteria used to retrieve data from a persistent store.
///
/// This protocol provides a high level type for request objects to conform to.
///
/// At this time it only provides a single paramter for a fetch limit, but provides the basis for
/// expanding the requirements of request types in future versions of this library.
///
/// Also, the benefit of defining the request type as a protocol rather than an abstract class is
/// that since your underlying data store will most likely have its own request type, you could
/// simply extend the native request type by making it conform to this protocol rather than
/// creating a redundant wrapper object.
///
/// For example, CoreData has its own `NSFetchRequest` which is an object that defines
/// the search criteria used to retrieve data within the context of CoreData. Therefore instead
/// of creating a whole new request object, you could simply extend `NSFetchRequest` such
/// that it conform to `DataStoreRequest`.
///
/// In this example, we extend CoreData's native `NSFetchRequest` to conform to
/// the `DataStoreRequest` protocol which allows us to use it as the request type.
///
///     extension NSFetchRequest: DataStoreRequest {
///
///     }
///
/// If your "data store" interacts with an API, you'll most likely create your own custom request
/// object that conforms to this protocol.
public protocol DataStoreRequest {
    /// The fetch limit of the fetch request.
    ///
    /// The fetch limit specifies the maximum number of objects that a request should return
    /// when executed. You should do your best to respect this value when querying your
    /// underlying data store, however if you don't, then the results controller internally caps
    /// results at this limit.
    ///
    /// A value of 0 indicates no maximum limit (provided by the default implementation).
    var fetchLimit: Int { get set }
}
