//
//  VenueById+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/7/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension VenueById: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [identifierKey: values[identifierKey]!]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        identifier = values[VenueById.identifierKey] as! String
        
        venue = try service.managedObject(of: PortlVenue.self, forValues: values[VenueById.venueKey] as! Dictionary<String, Any>, in: self.managedObjectContext!)
        
        for eventValues in (values[VenueById.eventsKey] as? Array<Dictionary<String, Any>>) ?? [] {
            let event = try service.managedObject(of: PortlEvent.self, forValues: eventValues, in: self.managedObjectContext!)
            event.addToVenueQueries(self)
        }
        
        timestamp = NSDate()
    }
        
    public static let requiredKeys = [identifierKey, venueKey, eventsKey]
    
    // MARK: Properties (Private Static Constant)
    
    private static let venueKey = "venue"
    private static let eventsKey = "events"
    static let identifierKey = "identifier"
}
