//
//  VenueKeywordSearch+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension VenueKeywordSearch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<VenueKeywordSearch> {
        return NSFetchRequest<VenueKeywordSearch>(entityName: "VenueKeywordSearch")
    }
	
	@NSManaged public var lat: Double
	@NSManaged public var lng: Double
	@NSManaged public var withinDistance: Double
}
