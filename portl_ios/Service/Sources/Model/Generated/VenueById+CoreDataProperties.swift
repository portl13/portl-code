//
//  VenueById+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/7/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension VenueById {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VenueById> {
        return NSFetchRequest<VenueById>(entityName: "VenueById")
    }

    @NSManaged public var venue: PortlVenue?
    @NSManaged public var events: PortlEvent?

}
