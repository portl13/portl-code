//
//  PortlArtist+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/2/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension PortlArtist: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return ["identifier" : values[idKey]!]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        identifier = values[PortlArtist.idKey] as! String
        timestamp = NSDate()
        
        imageURL = values[PortlArtist.imageUrlKey] as? String
        name = values[PortlArtist.nameKey] as! String
        source = values[PortlArtist.sourceKey] as! Int16
        url = values[PortlArtist.urlKey] as? String
        
        if let aboutValues = values[PortlArtist.aboutKey] {
            about = try service.managedObject(of: About.self, forValues: aboutValues as! Dictionary<String, Any>, in: self.managedObjectContext!)
        }
    }
        
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    
    public static let requiredKeys = [idKey, sourceKey]
    public static let idKey = "id"

    // MARK: Properties (Private Static Constant)
    private static let imageUrlKey = "imageUrl"
    private static let nameKey = "name"
    private static let sourceKey = "source"
    private static let urlKey = "url"
    private static let aboutKey = "description"
}
