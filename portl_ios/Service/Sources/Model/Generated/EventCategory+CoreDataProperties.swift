//
//  EventCategory+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 7/4/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension EventCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventCategory> {
        return NSFetchRequest<EventCategory>(entityName: "EventCategory")
    }

	@NSManaged public var name: String
    @NSManaged public var orderIndex: Int16
    @NSManaged public var events: NSSet?

}

// MARK: Generated accessors for events
extension EventCategory {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: PortlEvent)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: PortlEvent)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)

}
