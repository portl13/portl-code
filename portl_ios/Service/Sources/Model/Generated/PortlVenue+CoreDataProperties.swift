//
//  PortlVenue+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/8/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension PortlVenue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PortlVenue> {
        return NSFetchRequest<PortlVenue>(entityName: "PortlVenue")
    }

    @NSManaged public var url: String?
    @NSManaged public var address: Address?
    @NSManaged public var name: String?
    @NSManaged public var source: Int16
    @NSManaged public var location: PortlLocation
    @NSManaged public var events: NSSet?

}

// MARK: Generated accessors for events
extension PortlVenue {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: PortlEvent)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: PortlEvent)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)

}
