//
//  CoreDataStoreConnector.swift
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

extension NSManagedObject: Identifiable {
    public var id: String { return self.objectID.uriRepresentation().absoluteString }
}

final class CoreDataStoreConnector<EntityType: NSManagedObject>: CRUDStoreConnector<CoreDataStoreRequest<EntityType>> {
    
    let managedObjectContext: NSManagedObjectContext
    
    
    // MARK: - Private Properties
    
    private var managedObjectContextChangeObserver: AnyObject?
    
    
    // MARK: - StoreConnector
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        super.init()
    }
    
    override func execute(_ query: ObserverQuery<CoreDataStoreRequest<EntityType>>) {
        super.execute(query)
        
        guard let nsFetchRequest = query.storeRequest.nsFetchRequest else {
            return
        }
        
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

        // attach new observer
        managedObjectContextChangeObserver =
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange,
                object: self.managedObjectContext,
                queue: nil,
                using: { [unowned self] (note) in
                    self.handleContextObjectsDidChangeNotification(note, query: query)
                })

        // execute the fetch request
        let fetch = NSAsynchronousFetchRequest(fetchRequest: nsFetchRequest) { (result) in
            guard let objects = result.finalResult else { return }
            objects.forEach { self.enqueue(inserted: $0, for: query) }
        }

        try! managedObjectContext.execute(fetch)
    }

    override func stop(_ query: ObserverQuery<CoreDataStoreRequest<EntityType>>) {
        super.stop(query)

        // remove previous observer if attached
        if let managedObjectContextChangeObserver = managedObjectContextChangeObserver {
            NotificationCenter.default.removeObserver(managedObjectContextChangeObserver)
        }
    }
    
}

extension CoreDataStoreConnector {
    private func handleContextObjectsDidChangeNotification(_ notification: Notification, query: ObserverQuery<CoreDataStoreRequest<EntityType>>) {
        guard let nsFetchRequest = query.storeRequest.nsFetchRequest else {
            return
        }
        
        let entityName = nsFetchRequest.entityName!

        // enqueue insertions of `EntityType`
        let insertedObjs = notification.userInfo?[NSInsertedObjectsKey] as? Set<EntityType> ?? []
        insertedObjs.filter({ $0.entity.name == entityName }).forEach({ self.enqueue(inserted: $0, for: query) })

        // enqueue updates of `EntityType`
        let updatedObjs = notification.userInfo?[NSUpdatedObjectsKey] as? Set<EntityType> ?? []
        updatedObjs.filter({ $0.entity.name == entityName }).forEach({ self.enqueue(updated: $0, for: query) })
        
        // enqueue deletions of `EntityType`
        let deletedObjs = notification.userInfo?[NSDeletedObjectsKey] as? Set<EntityType> ?? []
        deletedObjs.filter({ $0.entity.name == entityName }).forEach({ self.enqueue(deleted: $0, for: query) })

        // process immediately
        self.processPendingChanges(for: query)
    }
}
