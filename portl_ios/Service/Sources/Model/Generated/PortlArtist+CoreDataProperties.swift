//
//  PortlArtist+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/3/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension PortlArtist {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PortlArtist> {
        return NSFetchRequest<PortlArtist>(entityName: "PortlArtist")
    }

    @NSManaged public var imageURL: String?
    @NSManaged public var name: String
    @NSManaged public var source: Int16
    @NSManaged public var url: String?
    @NSManaged public var about: About?
    @NSManaged public var byIdQuery: ArtistById?
    @NSManaged public var events: NSSet?
}

// MARK: Generated accessors for events
extension PortlArtist {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: PortlEvent)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: PortlEvent)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)

}
