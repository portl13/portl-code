//
//  ArtistById+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/3/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension ArtistById: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [identifierKey: values[identifierKey]!]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        identifier = values[ArtistById.identifierKey] as! String
        
        artist = try service.managedObject(of: PortlArtist.self, forValues: values[ArtistById.artistKey] as! Dictionary<String, Any>, in: self.managedObjectContext!)
        
        for eventValues in (values[ArtistById.eventsKey] as? Array<Dictionary<String, Any>>) ?? [] {
            let event = try service.managedObject(of: PortlEvent.self, forValues: eventValues, in: self.managedObjectContext!)
            event.addToArtistQueries(self)
			event.artist = artist
        }
        
        timestamp = NSDate()
    }
	
    public static let requiredKeys = [identifierKey, artistKey, eventsKey]

    // MARK: Properties (Private Static Constant)
    
    private static let artistKey = "artist"
    private static let eventsKey = "events"
    private static let identifierKey = "identifier"
}
