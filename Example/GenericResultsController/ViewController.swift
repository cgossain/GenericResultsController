//
//  ViewController.swift
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

import CoreData
import UIKit
import GenericResultsController

extension FetchedResultsConfiguration where ResultType == Event {
    /// Creates and returns a standard results configuration for Event.
    static func makeDefaultConfiguration() -> FetchedResultsConfiguration<Event> {
        var configuration = FetchedResultsConfiguration<Event>()
        configuration.sectionNameProvider = {
            return $0.category
        }
        
//        configuration.areInIncreasingOrder = { lhs, rhs in
//            return lhs.timestamp! < rhs.timestamp!
//        }
        
        return configuration
    }
}

class ViewController: UITableViewController {
    private(set) var fetchedResultsController: FetchedResultsController<Event, NSFetchRequest<Event>>!
    
    var managedObjectContext: NSManagedObjectContext { return CoreDataManager.shared.persistentContainer.viewContext }
    
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem
        
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
        fetchRequest.returnsObjectsAsFaults = false
        
        if #available(iOS 14.0, *) {
            let addButton = UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { (action) in
                self.insertNewObject(action)
            }))
            
            let refreshButton = UIBarButtonItem(systemItem: .refresh, primaryAction: UIAction(handler: { (action) in
                self.fetchedResultsController.performFetch(storeRequest: fetchRequest)
            }))
            navigationItem.rightBarButtonItems = [addButton, refreshButton]
            
            refreshControl = UIRefreshControl()
            refreshControl?.addAction(UIAction(handler: { (action) in
                self.fetchedResultsController.performFetch(storeRequest: fetchRequest)
            }), for: .valueChanged)
        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        configureResultsController()
        
        fetchedResultsController.performFetch(storeRequest: fetchRequest)
    }
    
    private func configureResultsController() {
        fetchedResultsController = FetchedResultsController(storeConnector: CoreDataStoreConnector(managedObjectContext: self.managedObjectContext))
        
        fetchedResultsController.delegate.controllerResultsConfiguration = { (controller, request) in
            return .makeDefaultConfiguration()
        }
        
        // table view diffing
        fetchedResultsController.changeTracker.controllerDidChangeResults = { [unowned self] (controller, difference) in
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

            self.refreshControl?.endRefreshing()
        }
        
        fetchedResultsController.delegate.controllerWillChangeContent = { (controller) in
            print("Will change content.")
        }

        fetchedResultsController.delegate.controllerDidChangeContent = { (controller) in
            print("Did change content.")
//            self.tableView.reloadData()
//            self.refreshControl?.endRefreshing()
        }
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
        let obj = try! fetchedResultsController.object(at: indexPath)
        configureCell(cell, with: obj)
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
            CoreDataManager.shared.saveContext()
        }
    }
}

extension ViewController {
    @objc func insertNewObject(_ sender: Any) {
        let context = self.managedObjectContext
        let newEvent = Event(context: context)

        // If appropriate, configure the new managed object.
        let now = Date()
        print("New Event with Date: \(now)")
        newEvent.timestamp = now
        
        // Set a random category to demonstrate sectionning
        if arc4random_uniform(2) == 0 {
            newEvent.category = "Category A"
        }
        else {
            newEvent.category = "Category B"
        }
        
        // Save the context.
        CoreDataManager.shared.saveContext()
    }
}

extension ViewController {
    func configureCell(_ cell: UITableViewCell, with event: Event) {
        cell.textLabel!.text = event.timestamp!.description
    }
}

