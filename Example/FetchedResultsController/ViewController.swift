//
//  ViewController.swift
//  FetchedResultsController
//
//  Created by cgossain on 03/21/2020.
//  Copyright (c) 2020 cgossain. All rights reserved.
//

import UIKit
import FetchedResultsController

class ViewController: UITableViewController {
    lazy var fetchedResultsController: FetchedResultsController<ExampleDBFetchRequest, ExampleModel> = {
        let fetchRequest = ExampleDBFetchRequest()
        let persistentStoreConnector = ExampleDBConnector()
        let fetchedResultsController = FetchedResultsController(fetchRequest: fetchRequest, persistentStoreConnector: persistentStoreConnector, sectionNameKeyPath: "category")
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        
        // implement table view row diffing
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
        }
        
//        fetchedResultsController.delegate.controllerWillChangeContent = { (controller) in
//            print("Will change content.")
//        }
//
//        fetchedResultsController.delegate.controllerDidChangeContent = { [unowned self] (controller) in
//            print("Did change content.")
//            self.tableView.reloadData()
//        }

        fetchedResultsController.performFetch()
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
}

extension ViewController {
    func configureCell(_ cell: UITableViewCell, with obj: ExampleModel) {
        cell.textLabel?.text = obj.name
    }
}
