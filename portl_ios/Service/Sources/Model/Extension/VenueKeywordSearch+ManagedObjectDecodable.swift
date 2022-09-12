//
//  VenueKeywordSearch+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/14/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService
import CoreLocation

extension VenueKeywordSearch: ManagedObjectDecodable {
	public static func predicateForCacheLookup(keyword: String, pageSize: Int, lat: Double, lng: Double, withinDistance: Double) -> NSPredicate {
        let formatString = "keyword == %@ AND pageSize == %@ AND lat == %@ AND lng == %@ AND withinDistance == %@"
        let formatValues: [Any] = [keyword, pageSize as NSNumber, lat as NSNumber, lng as NSNumber, withinDistance as NSNumber]
        return NSPredicate(format: formatString, argumentArray: formatValues)
    }
    
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return [keywordKey: values[keywordKey]!, pageSizeKey: values[pageSizeKey]!, totalCountKey: values[totalCountKey]!, latKey: values[latKey]!, lngKey: values[lngKey]!]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        timestamp = NSDate()
        keyword = values[VenueKeywordSearch.keywordKey] as! String
        pageSize = values[VenueKeywordSearch.pageSizeKey] as! Int16
        totalCount = values[VenueKeywordSearch.totalCountKey] as! Int16
        lat = values[VenueKeywordSearch.latKey] as! Double
		lng = values[VenueKeywordSearch.lngKey] as! Double
		
        let page = try service.managedObject(of: SearchPage.self, forValues: values, in: self.managedObjectContext!)
        page.search = self
        
        for var itemValues in (values[VenueKeywordSearch.itemsKey] as? Array<Dictionary<String, Any>>) ?? [] {
			let venueValues = itemValues[VenueKeywordSearchItem.venueKey] as! Dictionary<String, Any>
			let venueIdentifier = venueValues[PortlVenue.idKey] as! String
			itemValues[VenueKeywordSearchItem.venueIdentifierKey] = venueIdentifier
			
            let item = try service.managedObject(of: VenueKeywordSearchItem.self, forValues: itemValues, in: self.managedObjectContext!)
			let venueLocation = CLLocation(latitude: item.venue.location.latitude, longitude: item.venue.location.longitude)
			let userLocation = CLLocation(latitude: lat, longitude: lng)
			item.distanceFromUserMeters = userLocation.distance(from: venueLocation)
			item.addToSearchPages(page)
        }
    }
    
    public func setAttributes(forValues values: Dictionary<String, Any>) throws {}
    
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    public static let requiredKeys = [keywordKey, pageSizeKey, totalCountKey, itemsKey, latKey, lngKey]
    
    // MARK: Properties (Private Static Constant)
	private static let latKey = "lat"
	private static let lngKey = "lng"

    // MARK: Properties (Private Static Constant, From Superclass)
	private static let keywordKey = "keyword"
    private static let pageKey = "page"
    private static let pageSizeKey = "pageSize"
    private static let totalCountKey = "totalCount"
    private static let itemsKey = "items"
}
