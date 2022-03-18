//
//  CoreDataStore.swift
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
import CoreData
import GenericResultsController

extension NSFetchRequest: DataStoreRequest {
    
}

extension NSManagedObject: InstanceIdentifiable {
    public var id: String { return self.objectID.uriRepresentation().absoluteString }
}

final class CoreDataStore<EntityType: NSManagedObject>: DataStore<EntityType, NSFetchRequest<EntityType>> {
    
    /// The managed object context.
    let managedObjectContext: NSManagedObjectContext
    
    
    // MARK: - Private Properties
    
    /// The notification observers keyed by each unique query instance.
    private var observersByQueryID: [AnyHashable: Any] = [:]
    
    
    // MARK: - StoreConnector
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    
    override func execute(_ query: DataStoreQuery<EntityType, NSFetchRequest<EntityType>>) {
        super.execute(query)
        
        // perform the query and then call the query's `enqueue` method when
        // data becomes available
        //
        // note if your database supports observing changes to the
        // executed query you can setup observers here and then call
        // the query's `enqueue` method to add incremental changes
        // to the initial fetch results; these would then be picked
        // up by the results controller providing realtime updates to
        // the displayed results
        //
        // in this example we're executing a core data fetch request, and
        // then observing the for `NSManagedObjectContextObjectsDidChange` notification
        // to detect further incrementation changes

        // note, realistically you would use NSFetchedResultsController if you're
        // using CoreData.
        
        // observe incremental changes (since the last save)
        observersByQueryID[query.id] = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: self.managedObjectContext,
            queue: nil,
            using: { [unowned self] (note) in
                // enqueue incremental changes
                self.handleContextObjectsDidChangeNotification(note, query: query)
            })
        
        // enqueue initial fetch results
        let fetch = NSAsynchronousFetchRequest(fetchRequest: query.request) { [unowned self] (result) in
            if self.observersByQueryID[query.id] == nil {
                return
            }
            
            // enqueue each result into the query
            guard let objects = result.finalResult else { return }
            query.enqueue(objects, as: .insert)
        }
        try! managedObjectContext.execute(fetch)
    }

    override func stop(_ query: DataStoreQuery<EntityType, NSFetchRequest<EntityType>>) {
        super.stop(query)
        if let observer = observersByQueryID[query.id] {
            NotificationCenter.default.removeObserver(observer)
            observersByQueryID[query.id] = nil
        }
    }
    
}

extension CoreDataStore {
    private func handleContextObjectsDidChangeNotification(_ notification: Notification, query: DataStoreQuery<EntityType, NSFetchRequest<EntityType>>) {
        if observersByQueryID[query.id] == nil {
            return
        }
        
        let entityName = query.request.entityName!

        // enqueue insertions of `EntityType`
        let insertedObjs = notification.userInfo?[NSInsertedObjectsKey] as? Set<EntityType> ?? []
        query.enqueue(insertedObjs.filter({ $0.entity.name == entityName }), as: .insert)

        // enqueue updates of `EntityType`
        let updatedObjs = notification.userInfo?[NSUpdatedObjectsKey] as? Set<EntityType> ?? []
        query.enqueue(updatedObjs.filter({ $0.entity.name == entityName }), as: .update)
        
        // enqueue deletions of `EntityType`
        let deletedObjs = notification.userInfo?[NSDeletedObjectsKey] as? Set<EntityType> ?? []
        query.enqueue(deletedObjs.filter({ $0.entity.name == entityName }), as: .delete)
        
        // process immediately
        query.processPendingChanges()
    }
}
