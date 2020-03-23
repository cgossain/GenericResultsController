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
        
        fetchedResultsController.delegate.controllerWillChangeContent = { (controller) in
            print("Will change content.")
        }

        fetchedResultsController.delegate.controllerDidChangeContent = { [unowned self] (controller) in
            print(controller.description)
            self.tableView.reloadData()
        }

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
        cell.textLabel?.text = fetchedResultsController.sections[indexPath.section].objects[indexPath.row].name
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return fetchedResultsController.sections[section].name
    }
}
