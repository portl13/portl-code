//
//  ArtistById+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/3/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ArtistById {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArtistById> {
        return NSFetchRequest<ArtistById>(entityName: "ArtistById")
    }

    @NSManaged public var artist: PortlArtist?
    @NSManaged public var events: NSSet?
}

// MARK: Generated accessors for events
extension ArtistById {

    @objc(addEventsObject:)
    @NSManaged public func addToEvents(_ value: PortlEvent)

    @objc(removeEventsObject:)
    @NSManaged public func removeFromEvents(_ value: PortlEvent)

    @objc(addEvents:)
    @NSManaged public func addToEvents(_ values: NSSet)

    @objc(removeEvents:)
    @NSManaged public func removeFromEvents(_ values: NSSet)

}
