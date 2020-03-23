//
//  ExampleCategoryType.swift
//  FetchedResultsController_Example
//
//  Created by Christian Gossain on 2020-03-22.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation

struct ExampleCategoryType: RawRepresentable {
    let rawValue: Int
}

extension ExampleCategoryType {
    static let one = ExampleCategoryType(rawValue: 1)
    static let two = ExampleCategoryType(rawValue: 2)
    static let three = ExampleCategoryType(rawValue: 3)
    static let four = ExampleCategoryType(rawValue: 4)
}
