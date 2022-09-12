//
//  EventSearchItem+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/25/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension EventSearchItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventSearchItem> {
        return NSFetchRequest<EventSearchItem>(entityName: "EventSearchItem")
    }

	@NSManaged public var eventIdentifier: String
    @NSManaged public var distance: Double
    @NSManaged public var startDate: NSDate
    @NSManaged public var event: PortlEvent

}
