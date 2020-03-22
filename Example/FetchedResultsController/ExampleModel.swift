//
//  ExampleModel.swift
//  FetchedResultsController_Example
//
//  Created by Christian Gossain on 2020-03-21.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation
import FetchedResultsController

class ExampleModel: FetchRequestResult {
    let objectID: String = UUID().uuidString
    
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    func sectionKeyValue(forSectionNameKeyPath sectionNameKeyPath: String) -> String? {
        return nil
    }
    
    static func == (lhs: ExampleModel, rhs: ExampleModel) -> Bool {
        return lhs.objectID == rhs.objectID
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(objectID)
    }
}
