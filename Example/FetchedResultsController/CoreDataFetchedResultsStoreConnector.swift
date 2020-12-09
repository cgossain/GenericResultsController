//
//  CoreDataFetchedResultsStoreConnector.swift
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
    public var id: String { return self.objectID.description }
}

final class CoreDataFetchedResultsStoreConnector<EntityType: NSManagedObject>: FetchedResultsStoreConnector<CoreDataFetchedResultsStoreRequest<EntityType>, EntityType> {
    private var managedObjectContextChangeObserver: AnyObject?
    private var currentFetchRequest: NSFetchRequest<EntityType>!
    
    
    // MARK: - FetchedResultsStoreConnector
    override func execute(_ request: CoreDataFetchedResultsStoreRequest<EntityType>) {
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
        
        // keep track of the executed fetch request
        currentFetchRequest = request.fetchRequest
        
        // remove the previous observer if attached
        if let managedObjectContextChangeObserver = managedObjectContextChangeObserver {
            NotificationCenter.default.removeObserver(managedObjectContextChangeObserver)
        }
        
        // attach a new observer
        managedObjectContextChangeObserver =
            NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: request.managedObjectContext, queue: nil, using: { [unowned self] (note) in
                self.handleContextObjectsDidChangeNotification(note)
            })
        
        // execute the fetch request
        request.managedObjectContext.perform {
            do {
                let results = try request.fetchRequest.execute()
                results.forEach({ self.enqueue(inserted: $0) })
            }
            catch {
                print(error)
            }
        }
    }
}

extension CoreDataFetchedResultsStoreConnector {
    private func handleContextObjectsDidChangeNotification(_ notification: Notification) {
        let entityName = currentFetchRequest.entityName!
        
        // inserted
        let insertedObjectsSet = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> ?? []
        let filteredInserted = insertedObjectsSet.filter({ $0.entity.name == entityName }) as? Set<EntityType>
        filteredInserted?.forEach({ self.enqueue(inserted: $0) })
        
        // updated
        let updatedObjectsSet = notification.userInfo?[NSUpdatedObjectsKey] as? Set<NSManagedObject> ?? []
        let filteredUpdated = updatedObjectsSet.filter({ $0.entity.name == entityName }) as? Set<EntityType>
        filteredUpdated?.forEach({ self.enqueue(updated: $0) })
        
        // deleted
        let deletedObjectsSet = notification.userInfo?[NSDeletedObjectsKey] as? Set<NSManagedObject> ?? []
        let filteredDeleted = deletedObjectsSet.filter({ $0.entity.name == entityName }) as? Set<EntityType>
        filteredDeleted?.forEach({ self.enqueue(removed: $0) })
        
        self.processPendingChanges()
    }
}
