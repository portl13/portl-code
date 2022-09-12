//
//  EventSearchItem+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/3/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension EventSearchItem: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [eventIdentifierKey: values[eventIdentifierKey]!]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        distance = values[EventSearchItem.distanceKey] as! Double
        event = try service.managedObject(of: PortlEvent.self, forValues: values[EventSearchItem.eventKey] as! Dictionary<String, Any>, in: self.managedObjectContext!)
        startDate = event.localStartDate
    }
        
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    public static let requiredKeys = [eventKey]
    
    // MARK: Properties (Private Static Constant)
    private static let distanceKey = "distance"
    static let eventKey = "event"
	static let eventIdentifierKey = "eventIdentifier"
}
