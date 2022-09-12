//
//  ArtistKeywordSearchItem+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension ArtistKeywordSearchItem: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return [artistIdentifierKey: values[artistIdentifierKey]!]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		artistIdentifier = values[ArtistKeywordSearchItem.artistIdentifierKey] as! String
        artist = try service.managedObject(of: PortlArtist.self, forValues: values[ArtistKeywordSearchItem.artistKey] as! Dictionary<String, Any>, in: self.managedObjectContext!)
        for eventValues in (values[ArtistKeywordSearchItem.eventsKey] as? Array<Dictionary<String, Any>>) ?? [] {
            let event = try service.managedObject(of: PortlEvent.self, forValues: eventValues, in: self.managedObjectContext!)
            self.addToEvents(event)
        }
    }
	
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    
    public static let requiredKeys = [artistKey, eventsKey, artistIdentifierKey]
	public static let artistKey = "artist"
	public static let artistIdentifierKey = "artistIdentifier"
	
    // MARK: Properties (Private Static Constant)
    
    private static let eventsKey = "events"
}
