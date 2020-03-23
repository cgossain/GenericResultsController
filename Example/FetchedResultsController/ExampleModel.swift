//
//  ExampleModel.swift
//  FetchedResultsController_Example
//
//  Created by Christian Gossain on 2020-03-21.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import FetchedResultsController

//extension ExampleModel: IdentifiableFetchRequestResult {
//    var objectID: String { return key }
//}

extension ExampleModel: IdentifiableFetchRequestResult {
    var objectID: String {
        return key
    }
}

class ExampleModel: NSObject {
    let key: String = UUID().uuidString
    
    @objc let name: String
    
    @objc let category: Int
    
    init(name: String, categoryType: ExampleCategoryType) {
        self.name = name
        self.category = categoryType.rawValue
    }
}
