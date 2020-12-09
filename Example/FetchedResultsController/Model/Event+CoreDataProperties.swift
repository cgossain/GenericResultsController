//
//  Event+CoreDataProperties.swift
//  FetchedResultsController_Example
//
//  Created by Christian Gossain on 2020-03-28.
//  Copyright © 2020 CocoaPods. All rights reserved.
//
//

import Foundation
import CoreData


extension Event {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Event> {
        return NSFetchRequest<Event>(entityName: "Event")
    }

    @NSManaged public var category: String?
    @NSManaged public var timestamp: Date?

}
