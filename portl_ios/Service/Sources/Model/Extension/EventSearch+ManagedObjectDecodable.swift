//
//  EventSearch+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/3/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension EventSearch: ManagedObjectDecodable {
    public static func predicateForCacheLookup(latitude: Double, longitude: Double, date: Date, startingWithin: Int?, distance: Double?, pageSize: Int, categories: String?) -> NSPredicate {
        var formatString = "(%@ <= \(latitudeKey)) AND (\(latitudeKey) <= %@)"
        var formatValues: [Any] = [(latitude - 0.0001) as NSNumber, (latitude + 0.0001) as NSNumber]
        
        formatString += " AND (%@ <= \(longitudeKey)) AND (\(longitudeKey) <= %@)"
        formatValues.append(contentsOf: [(longitude - 0.0001) as NSNumber, (longitude + 0.0001) as NSNumber])
        
        formatString += " AND \(startingAfterKey) == %@"
        formatValues.append(date as NSDate)
        
        formatString += " AND \(pageSizeKey) == %@"
        formatValues.append(pageSize as NSNumber)
        
        if let sw = startingWithin {
            formatString += " AND startingWithinDaysValue == %@"
            formatValues.append(sw as NSNumber)
        } else {
            formatString += "AND startingWithinDaysValue == NIL"
        }
        
        if let d = distance {
            formatString += " AND \(maxDistanceKey) == %@"
            formatValues.append(d as NSNumber)
        } else {
            formatString += "AND \(maxDistanceKey) == NIL"
        }
        
        if let c = categories {
            formatString += " AND \(categoriesKey) == %@"
            formatValues.append(c)
        } else {
            formatString += "AND \(categoriesKey) == NIL"
        }
        
        return NSPredicate(format: formatString, argumentArray: formatValues)
    }
    
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        let unwrapped = ["latitude": values[latitudeKey],
                    "longitude": values[longitudeKey],
                    "maxDistanceMiles": values[maxDistanceKey],
                    "startingAfter": values[startingAfterKey].flatMap { d in NSDate(timeIntervalSince1970: (d as! Double)) },
                    "startingWithinDaysValue": values[startingWithinKey] as? NSNumber,
                    "totalCount": values[totalCountKey],
                    "pageSize": values[pageSizeKey],
                    "categories": values[categoriesKey].flatMap {c in (c as! Array<String>).sorted().joined()}
            ].filter {$0.value != nil}.mapValues { (value: Any?) -> Any in return value!}
        
        return unwrapped
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        latitude = values[EventSearch.latitudeKey] as! Double
        longitude = values[EventSearch.longitudeKey] as! Double
        
        startingAfter = values[EventSearch.startingAfterKey].flatMap { d in NSDate(timeIntervalSince1970: (d as! Double)) }
        
        if let distance = values[EventSearch.maxDistanceKey] {
            maxDistanceMiles = distance as! Double
        }
		
		startingWithinDays = values[EventSearch.startingWithinKey] as? Int

        categories = values[EventSearch.categoriesKey].flatMap {c in (c as! Array<String>).sorted().joined()}
        
        // Superclass
        pageSize = values[EventSearch.pageSizeKey] as! Int16
        totalCount = values[EventSearch.totalCountKey] as! Int16
        timestamp = NSDate()
        
        let page = try service.managedObject(of: SearchPage.self, forValues: values, in: self.managedObjectContext!)
        page.search = self
        
        for var eventItemValues in (values[EventSearch.itemsKey] as? Array<Dictionary<String, Any>>) ?? [] {
			let eventValues = eventItemValues[EventSearchItem.eventKey] as! Dictionary<String, Any>
			let eventIdentifier = eventValues[PortlEvent.idKey]
			eventItemValues[EventSearchItem.eventIdentifierKey] = eventIdentifier
			
			let item = try service.managedObject(of: EventSearchItem.self, forValues: eventItemValues, in: self.managedObjectContext!)
			item.addToSearchPages(page)
        }
    }
        
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    public static let requiredKeys = [latitudeKey, longitudeKey, pageKey, totalCountKey, timestampKey, itemsKey]
    
    // MARK: Properties (Private Static Constant)
    private static let maxDistanceKey = "maxDistanceMiles"
    private static let startingAfterKey = "startingAfter"
    private static let startingWithinKey = "startingWithinDays"
    private static let categoriesKey = "categories"
    private static let latitudeKey = "latitude"
    private static let longitudeKey = "longitude"
    
    // MARK: Properties (Private Static Constant, From Superclass)
    private static let pageKey = "page"
    private static let pageSizeKey = "pageSize"
    private static let totalCountKey = "totalCount"
    private static let timestampKey = "timestamp"
    private static let itemsKey = "items"
}
