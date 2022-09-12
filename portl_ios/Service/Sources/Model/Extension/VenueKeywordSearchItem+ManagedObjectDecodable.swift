//
//  VenueKeywordSearchItem+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/14/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension VenueKeywordSearchItem: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [venueIdentifierKey: values[venueIdentifierKey]!]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		venueIdentifier = values[VenueKeywordSearchItem.venueIdentifierKey] as! String
		venue = try service.managedObject(of: PortlVenue.self, forValues: values[VenueKeywordSearchItem.venueKey] as! Dictionary<String, Any>, in: self.managedObjectContext!)
        for eventValues in (values[VenueKeywordSearchItem.eventsKey] as? Array<Dictionary<String, Any>>) ?? [] {
            let event = try service.managedObject(of: PortlEvent.self, forValues: eventValues, in: self.managedObjectContext!)
            self.addToEvents(event)
        }
    }
        
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    
    public static let requiredKeys = [venueKey, eventsKey, venueIdentifierKey]
    
	public static let venueIdentifierKey = "venueIdentifier"
	public static let venueKey = "venue"
	
    // MARK: Properties (Private Static Constant)
    
    private static let eventsKey = "events"
}
