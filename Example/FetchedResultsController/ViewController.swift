//
//  ViewController.swift
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

import CoreData
import FetchedResultsController
import UIKit

class ViewController: UITableViewController {
    private(set) var fetchedResultsController: FetchedResultsController<CoreDataFetchedResultsStoreRequest<Event>, Event>!
    
    var managedObjectContext: NSManagedObjectContext { return CoreDataManager.shared.persistentContainer.viewContext }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItem = addButton
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        configureResultsController()
        
        fetchedResultsController.performFetch()
    }
    
    private func configureResultsController() {
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        fetchRequest.returnsObjectsAsFaults = false
        
        let storeRequest = CoreDataFetchedResultsStoreRequest(managedObjectContext: self.managedObjectContext, fetchRequest: fetchRequest)
        
        self.fetchedResultsController = FetchedResultsController(
            storeConnector: CoreDataFetchedResultsStoreConnector(),
            fetchRequest: storeRequest,
            sectionNameKeyPath: "category")
        
        // implement table view row diffing
        self.fetchedResultsController.changeTracker.controllerDidChangeResults = { [unowned self] (controller, difference) in
            self.tableView.performBatchUpdates({
                // apply section changes
                difference.enumerateSectionChanges { (section, sectionIndex, type) in
                    switch type {
                    case .insert:
                        self.tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
                    case .delete:
                        self.tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
                    default:
                        break
                    }
                }
                
                // apply row changes
                difference.enumerateRowChanges { (anObject, indexPath, type, newIndexPath) in
                    switch type {
                    case .insert:
                        self.tableView.insertRows(at: [newIndexPath!], with: .fade)
                    case .delete:
                        self.tableView.deleteRows(at: [indexPath!], with: .fade)
                    case .update:
                        let cell = self.tableView.cellForRow(at: indexPath!)!
                        self.configureCell(cell, with: anObject)
                    case .move:
                        self.tableView.moveRow(at: indexPath!, to: newIndexPath!)
                    }
                }
            })
            
            // save any changes that triggered this change
            CoreDataManager.shared.saveContext()
        }
        
//        fetchedResultsController.delegate.controllerWillChangeContent = { (controller) in
//            print("Will change content.")
//        }
//
//        fetchedResultsController.delegate.controllerDidChangeContent = { [unowned self] (controller) in
//            print("Did change content.")
//            self.tableView.reloadData()
//        }
    }
    
    
    // MARK: - UITableViewDataSource
    let cellIdentifier = "cellIdentifier"
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections[section].numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        configureCell(cell, with: fetchedResultsController.sections[indexPath.section].objects[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections[section].name
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let obj = try! fetchedResultsController.object(at: indexPath)
            let context = managedObjectContext
            context.delete(obj)
        }
    }
}

extension ViewController {
    @objc func insertNewObject(_ sender: Any) {
        let context = self.managedObjectContext
        let newEvent = Event(context: context)

        // If appropriate, configure the new managed object.
        newEvent.timestamp = Date()
        
        // Set a random category to demonstrate sectionning
        if arc4random_uniform(2) == 0 {
            newEvent.category = "Category A"
        }
        else {
            newEvent.category = "Category B"
        }
        

        // Save the context.
        do {
            try context.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}

extension ViewController {
    func configureCell(_ cell: UITableViewCell, with event: Event) {
        cell.textLabel!.text = event.timestamp!.description
    }
}
