//
//  ExampleDataStore.swift
//  FetchedResultsController_Example
//
//  Created by Christian Gossain on 2020-03-21.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import FetchedResultsController

let exampleData: [ExampleModel] = [
    ExampleModel(name: "Item 0"),
    ExampleModel(name: "Item 1"),
    ExampleModel(name: "Item 2"),
    ExampleModel(name: "Item 3"),
    ExampleModel(name: "Item 4"),
    ExampleModel(name: "Item 5"),
    ExampleModel(name: "Item 6"),
    ExampleModel(name: "Item 7"),
    ExampleModel(name: "Item 8"),
    ExampleModel(name: "Item 9")
]

final class ExampleDataStore: DataStore<ExampleFetchRequest, ExampleModel> {
    override func execute(_ request: ExampleFetchRequest, completion: ([ExampleModel]) -> Void) {
        completion(exampleData)
    }
}
