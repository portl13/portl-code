//
//  VenueKeywordSearchItem+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/14/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension VenueKeywordSearchItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VenueKeywordSearchItem> {
        return NSFetchRequest<VenueKeywordSearchItem>(entityName: "VenueKeywordSearchItem")
    }

	@NSManaged public var venueIdentifier: String
	@NSManaged public var distanceFromUserMeters: Double
    @NSManaged public var venue: PortlVenue
    @NSManaged public var events: NSSet?
}

// MARK: Generated accessors for events
extension VenueKeywordSearchItem {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: PortlEvent)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: PortlEvent)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)

}
