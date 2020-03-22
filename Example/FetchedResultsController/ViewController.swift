//
//  ViewController.swift
//  FetchedResultsController
//
//  Created by cgossain on 03/21/2020.
//  Copyright (c) 2020 cgossain. All rights reserved.
//

import UIKit
import FetchedResultsController

class ViewController: UIViewController {
    let fetchedResultsController = FetchedResultsController(dataStore: ExampleDataStore(), fetchRequest: ExampleFetchRequest(), sectionNameKeyPath: nil)
    
//    init() {
//        super.init(nibName: nil, bundle: nil)
//    }
    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        fetchedResultsController.delegate.controllerWillChangeContent = { (controller) in
            print("Will change content.")
        }
        
        fetchedResultsController.delegate.controllerDidChangeContent = { (controller) in
            print(controller.sections)
        }
        
        
        
        fetchedResultsController.performFetch()
    }
    
}

//extension ViewController: FetchedResultsControllerDelegate {
//    func controllerWillChangeContent<F, R>(_ controller: FetchedResultsController<F, R>) where F : FetchRequest, R : FetchRequestResult {
//
//    }
//
//    func controllerDidChangeContent<F, R>(_ controller: FetchedResultsController<F, R>) where F : FetchRequest, R : FetchRequestResult {
//
//    }
//
//
//}


//extension ViewController: FetchedResultsControllerDelegate {
////    func controllerWillChangeContent<FetchRequestType, ResultType>(_ controller: FetchedResultsController<FetchRequestType, ResultType>) where FetchRequestType : FetchRequest, ResultType : FetchRequestResult {
////        print("Will change content.")
////    }
////
////    func controllerDidChangeContent<FetchRequestType, ResultType>(_ controller: FetchedResultsController<FetchRequestType, ResultType>) where FetchRequestType : FetchRequest, ResultType : FetchRequestResult {
////        print(controller.sections)
////    }
//}

