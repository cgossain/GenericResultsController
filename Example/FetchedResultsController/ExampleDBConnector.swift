//
//  ExampleDBConnector.swift
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
