//
//  PortlEvent+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 3/31/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension PortlEvent: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return ["identifier" : values[idKey]!]
	}

	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		identifier = values[PortlEvent.idKey] as! String
		timestamp = NSDate()
		
		source = values[PortlEvent.sourceKey] as! Int16
		startDateTime = NSDate(timeIntervalSince1970: (values[PortlEvent.startDateTimeKey] as! Double) / 1000)
		localStartDate = (service as! ProvidesLocalStartDateFormatter).getLocalStartDate(fromString: (values[PortlEvent.localStartDateKey] as! String))
		
		title = values[PortlEvent.titleKey] as! String
		
		imageURL = values[PortlEvent.imageUrlKey] as? String
		values[PortlEvent.endDateTimeKey].flatMap { (value) in
			endDateTime =  NSDate(timeIntervalSince1970: (value as! Double) / 1000)
		}
		
		ticketPurchaseUrl = values[PortlEvent.ticketPurchaseUrlKey] as? String
		url = values[PortlEvent.urlKey] as? String
		
		let allCategoryValues = (values[PortlEvent.categoriesKey] as! Array<String>).enumerated().map { (index: Int, catString: String) -> Dictionary<String, Any> in
			return ["name": catString, "orderIndex": Int16(index)]
		}
		
		var categoryEntities = Array<EventCategory>()
		for categoryValues in allCategoryValues {
			let cat = try service.managedObject(of: EventCategory.self, forValues: categoryValues, in: self.managedObjectContext!)
			categoryEntities.append(cat)
		}
		categories = Set(categoryEntities) as NSSet
		
		if let aboutValues = values[PortlEvent.aboutKey] {
			about = try service.managedObject(of: About.self, forValues: aboutValues as! Dictionary<String, Any>, in: self.managedObjectContext!)
		}
		
		if let venueValues = values[PortlEvent.venueKey] {
			venue = try service.managedObject(of: PortlVenue.self, forValues: venueValues as! Dictionary<String, Any>, in: self.managedObjectContext!)
		}
		
		if let artistValues = values[PortlEvent.artistKey] {
			artist = try service.managedObject(of: PortlArtist.self, forValues: artistValues as! Dictionary<String, Any>, in: self.managedObjectContext!)
		}
	}
	
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    
    public static let requiredKeys = [idKey, sourceKey, startDateTimeKey, titleKey]
    
    // MARK: Properties (Private Static Constant)
    
    static let idKey = "id"
    private static let titleKey = "title"
    private static let imageUrlKey = "imageUrl"
    private static let aboutKey = "description"
    private static let startDateTimeKey = "startDateTime"
    private static let localStartDateKey = "localStartDate"
    private static let endDateTimeKey = "endDateTime"
    private static let categoriesKey = "categories"
    private static let venueKey = "venue"
    private static let artistKey = "artist"
    private static let urlKey = "url"
    private static let ticketPurchaseUrlKey = "ticketPurchaseUrl"
    private static let sourceKey = "source"
    
}
