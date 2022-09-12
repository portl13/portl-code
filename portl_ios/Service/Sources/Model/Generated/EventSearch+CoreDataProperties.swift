//
//  EventSearch+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/25/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension EventSearch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventSearch> {
        return NSFetchRequest<EventSearch>(entityName: "EventSearch")
    }

    @NSManaged public var categories: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var maxDistanceMiles: Double
    @NSManaged public var startingAfter: NSDate?
    @NSManaged public var startingWithinDaysValue: NSNumber?

}
