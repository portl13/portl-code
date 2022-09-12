//
//  Address+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/16/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension Address: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [:]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        street = values[Address.streetKey] as? String
        street2 = values[Address.street2Key] as? String
        city = values[Address.cityKey] as? String
        state = values[Address.stateKey] as? String
        zipcode = values[Address.zipcodeKey] as? String
        country = values[Address.countryKey] as? String
    }
        
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    
    public static let requiredKeys: [String] = []
    
    // MARK: Properties (Private Static Constant, From Superclass)
    
    private static let streetKey = "street"
    private static let street2Key = "street2"
    private static let cityKey = "city"
    private static let stateKey = "state"
    private static let zipcodeKey = "zipCode"
    private static let countryKey = "country"
}
