//
//  PortlLocation+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/8/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData
import MapKit

extension PortlLocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PortlLocation> {
        return NSFetchRequest<PortlLocation>(entityName: "PortlLocation")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var venues: NSSet?

}

// MARK: Generated accessors for venues
extension PortlLocation {

    @objc(addVenuesObject:)
    @NSManaged public func addToVenues(_ value: PortlVenue)

    @objc(removeVenuesObject:)
    @NSManaged public func removeFromVenues(_ value: PortlVenue)

    @objc(addVenues:)
    @NSManaged public func addToVenues(_ values: NSSet)

    @objc(removeVenues:)
    @NSManaged public func removeFromVenues(_ values: NSSet)

}


public extension PortlLocation {
	func toLocation() -> CLLocation {
		return CLLocation(latitude: latitude, longitude: longitude)
	}
}
