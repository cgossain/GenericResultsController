//
//  CoreDataStoreRequest.swift
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
import FetchedResultsController
import CoreData

final class CoreDataStoreRequest<EntityType: NSManagedObject>: StoreRequest {
    public typealias ResultType = EntityType
    
    /// The underlying NSFetchRequest.
    let nsFetchRequest: NSFetchRequest<EntityType>
    
    
    // MARK: - FetchRequest
    
    var fetchLimit: Int {
        get {
            return nsFetchRequest.fetchLimit
        }
        set {
            nsFetchRequest.fetchLimit = newValue
        }
    }
    
    var isIncluded: ((EntityType) -> Bool)?
    
    var areInIncreasingOrder: ((EntityType, EntityType) -> Bool)?
    
    
    // MARK: - Lifecycle
    
    init(nsFetchRequest: NSFetchRequest<EntityType>) {
        self.nsFetchRequest = nsFetchRequest
    }
    
    
    // MARK: - NSCopying
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = type(of: self).init(nsFetchRequest: self.nsFetchRequest.copy() as! NSFetchRequest<EntityType>)
        copy.fetchLimit = fetchLimit
        copy.isIncluded = isIncluded
        copy.areInIncreasingOrder = areInIncreasingOrder
        return copy
    }
}
