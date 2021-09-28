//
//  CoreDataStoreConnector.swift
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

extension NSFetchRequest: StoreRequest {
    
}

extension NSManagedObject: InstanceIdentifiable {
    public var id: String { return self.objectID.uriRepresentation().absoluteString }
}

final class CoreDataStoreConnector<EntityType: NSManagedObject>: DataStore<EntityType, NSFetchRequest<EntityType>> {
    
    let managedObjectContext: NSManagedObjectContext
    
    
    // MARK: - Private Properties
    
    private var managedObjectContextChangeObserversByQueryID: [AnyHashable: Any] = [:]
    
    
    // MARK: - StoreConnector
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    
    override func execute(_ query: StoreQuery<EntityType, NSFetchRequest<EntityType>>) {
        super.execute(query)
        
        // perform the query and then call the appropriate `enqueue` method
        // when data becomes available
        //
        // note if your database supports observing changes to the executed
        // query you can setup your observers here and then call the
        // appropriate `enqueue` method on the superclass; this would trigger
        // realtime updates to the displayed results

        // in this example we're executing the core data fetch request, and then
        // observing the for `NSManagedObjectContextObjectsDidChange` notification
        // to detect further incrementation changes

        // note, realistically you would use NSFetchedResultsController if you're
        // using CoreData.
        
        managedObjectContextChangeObserversByQueryID[query.id] = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange,
            object: self.managedObjectContext,
            queue: nil,
            using: { [unowned self] (note) in
                self.handleContextObjectsDidChangeNotification(note, query: query)
            })
        
        let fetch = NSAsynchronousFetchRequest(fetchRequest: query.storeRequest) { (result) in
            if self.managedObjectContextChangeObserversByQueryID[query.id] == nil {
                return
            }
            
            guard let objects = result.finalResult else { return }
            objects.forEach { query.enqueue($0, as: .insert) }
        }

        try! managedObjectContext.execute(fetch)
    }

    override func stop(_ query: StoreQuery<EntityType, NSFetchRequest<EntityType>>) {
        super.stop(query)
        if let observer = managedObjectContextChangeObserversByQueryID[query.id] {
            NotificationCenter.default.removeObserver(observer)
            managedObjectContextChangeObserversByQueryID[query.id] = nil
        }
    }
    
}

extension CoreDataStoreConnector {
    private func handleContextObjectsDidChangeNotification(_ notification: Notification, query: StoreQuery<EntityType, NSFetchRequest<EntityType>>) {
        if managedObjectContextChangeObserversByQueryID[query.id] == nil {
            return
        }
        
        let entityName = query.storeRequest.entityName!

        // enqueue insertions of `EntityType`
        let insertedObjs = notification.userInfo?[NSInsertedObjectsKey] as? Set<EntityType> ?? []
        insertedObjs.filter({ $0.entity.name == entityName }).forEach({ query.enqueue($0, as: .insert) })

        // enqueue updates of `EntityType`
        let updatedObjs = notification.userInfo?[NSUpdatedObjectsKey] as? Set<EntityType> ?? []
        updatedObjs.filter({ $0.entity.name == entityName }).forEach({ query.enqueue($0, as: .update) })

        // enqueue deletions of `EntityType`
        let deletedObjs = notification.userInfo?[NSDeletedObjectsKey] as? Set<EntityType> ?? []
        deletedObjs.filter({ $0.entity.name == entityName }).forEach({ query.enqueue($0, as: .delete) })

        // process immediately
        query.processPendingChanges()
    }
}
