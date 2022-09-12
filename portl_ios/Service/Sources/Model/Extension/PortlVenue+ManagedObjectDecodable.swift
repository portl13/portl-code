//
//  PortlVenue+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/2/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension PortlVenue: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return ["identifier" : values[idKey]!]
    }
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        identifier = values[PortlVenue.idKey] as! String
        timestamp = NSDate()
        
        source = values[PortlVenue.sourceKey] as! Int16
        name = values[PortlVenue.nameKey] as? String
        url = values[PortlVenue.urlKey] as? String
        
        if address != nil {
            self.managedObjectContext!.delete(address!)
        }
        
        let addressValues = values[PortlVenue.addressKey] as! Dictionary<String, String>
        address = try service.managedObject(of: Address.self, forValues: addressValues, in: self.managedObjectContext!)
        
        
        let locationValues = values[PortlVenue.locationKey] as! Dictionary<String, Double>
        location = try service.managedObject(of: PortlLocation.self, forValues: locationValues, in: self.managedObjectContext!)
    }
    
    public static let requiredKeys = [idKey, sourceKey]
    public static let idKey = "id"

    // MARK: Properties (Private Static Constant)
    private static let sourceKey = "source"
    private static let nameKey = "name"
    private static let addressKey = "address"
    private static let locationKey = "location"
    private static let urlKey = "url"
}
