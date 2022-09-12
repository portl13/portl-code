//
//  PortlEvent+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/3/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension PortlEvent {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PortlEvent> {
        return NSFetchRequest<PortlEvent>(entityName: "PortlEvent")
    }

    @NSManaged public var endDateTime: NSDate?
    @NSManaged public var imageURL: String?
    @NSManaged public var localStartDate: NSDate
    @NSManaged public var source: Int16
    @NSManaged public var startDateTime: NSDate
    @NSManaged public var ticketPurchaseUrl: String?
    @NSManaged public var title: String
    @NSManaged public var url: String?
    @NSManaged public var about: About?
    @NSManaged public var artist: PortlArtist?
    @NSManaged public var categories: NSSet
    @NSManaged public var searchItems: NSSet?
    @NSManaged public var venue: PortlVenue
    @NSManaged public var artistQueries: NSSet?
    @NSManaged public var venueQueries: NSSet?
	
	public func getPrimaryEventCategory() -> EventCategory {
		return categories.sortedArray(using: [NSSortDescriptor(key: "orderIndex", ascending: true)]).first as! EventCategory
	}
}

// MARK: Generated accessors for categories
extension PortlEvent {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: EventCategory)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: EventCategory)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

// MARK: Generated accessors for searchItems
extension PortlEvent {

    @objc(addSearchItemsObject:)
    @NSManaged public func addToSearchItems(_ value: EventSearchItem)

    @objc(removeSearchItemsObject:)
    @NSManaged public func removeFromSearchItems(_ value: EventSearchItem)

    @objc(addSearchItems:)
    @NSManaged public func addToSearchItems(_ values: NSSet)

    @objc(removeSearchItems:)
    @NSManaged public func removeFromSearchItems(_ values: NSSet)

}

// MARK: Generated accessors for artistQueries
extension PortlEvent {

    @objc(addArtistQueriesObject:)
    @NSManaged public func addToArtistQueries(_ value: ArtistById)

    @objc(removeArtistQueriesObject:)
    @NSManaged public func removeFromArtistQueries(_ value: ArtistById)

    @objc(addArtistQueries:)
    @NSManaged public func addToArtistQueries(_ values: NSSet)

    @objc(removeArtistQueries:)
    @NSManaged public func removeFromArtistQueries(_ values: NSSet)

}

// MARK: Generated accessors for venueQueries
extension PortlEvent {
    
    @objc(addVenueQueriesObject:)
    @NSManaged public func addToVenueQueries(_ value: VenueById)
    
    @objc(removeVenueQueriesObject:)
    @NSManaged public func removeFromVenueQueries(_ value: VenueById)
    
    @objc(addVenueQueries:)
    @NSManaged public func addToVenueQueries(_ values: NSSet)
    
    @objc(removeVenueQueries:)
    @NSManaged public func removeFromVenueQueries(_ values: NSSet)
    
}

// MARK: Generated accessors for keywordSearchItems
extension PortlEvent {
    
    @objc(addArtistKeywordSearchItemsObject:)
    @NSManaged public func addToArtistKeywordSearchItems(_ value: ArtistKeywordSearchItem)
    
    @objc(removeArtistKeywordSearchItemsObject:)
    @NSManaged public func removeFromArtistKeywordSearchItems(_ value: ArtistKeywordSearchItem)
    
    @objc(addArtistKeywordSearchItems:)
    @NSManaged public func addToArtistKeywordSearchItems(_ values: NSSet)
    
    @objc(removeArtistKeywordSearchItems:)
    @NSManaged public func removeFromArtistKeywordSearchItems(_ values: NSSet)
    
}

