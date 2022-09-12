//
//  PortlLocation+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/3/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension PortlLocation: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [latKey: values[latKey]!, lngKey: values[lngKey]!]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        latitude = values[PortlLocation.latKey] as! Double
        longitude = values[PortlLocation.lngKey] as! Double
    }
        
    // MARK: Properties (Static Constant, Seraializable)
    public static let requiredKeys = [latKey, lngKey]
    
    // MARK: Properties (Private Static Constant
    private static let latKey = "latitude"
    private static let lngKey = "longitude"
}
