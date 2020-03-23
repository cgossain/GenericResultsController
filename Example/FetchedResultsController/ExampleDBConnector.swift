//
//  ExampleDBConnector.swift
//  FetchedResultsController_Example
//
//  Created by Christian Gossain on 2020-03-21.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import FetchedResultsController

let exampleData: [ExampleModel] = [
    ExampleModel(name: "Item 0", categoryType: .one),
    ExampleModel(name: "Item 1", categoryType: .two),
    ExampleModel(name: "Item 2", categoryType: .three),
    ExampleModel(name: "Item 3", categoryType: .four),
    ExampleModel(name: "Item 4", categoryType: .one),
    ExampleModel(name: "Item 5", categoryType: .two),
    ExampleModel(name: "Item 6", categoryType: .three),
    ExampleModel(name: "Item 7", categoryType: .four),
    ExampleModel(name: "Item 8", categoryType: .one),
    ExampleModel(name: "Item 9", categoryType: .two)
]

final class ExampleDBConnector: PersistentStoreConnector<ExampleDBFetchRequest, ExampleModel> {
    override func execute(_ request: ExampleDBFetchRequest) {
        // perform the query and then call the appropriate `enqueue` method
        // when data becomes available
        //
        // note if your database supports observing changes to the executed
        // query you can setup your observers here and then call the
        // appropriate `enqueue` method on the superclass; this would trigger
        // realtime updates to the displayed results
        
        // in this example we're just providing the results of the query
        // by enqueuing an insertion for each returned object
        exampleData.forEach({ self.enqueue(inserted: $0) })
    }
}
