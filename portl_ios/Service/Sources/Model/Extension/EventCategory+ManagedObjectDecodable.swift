//
//  EventCategory+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/3/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension EventCategory: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [:]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        name = values[EventCategory.nameKey] as! String
        orderIndex = values[EventCategory.orderIndexKey] as! Int16
    }
        
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    
    public static let requiredKeys = [orderIndexKey, nameKey]
    
    // MARK: Properties (Private Static Constant)
    
    private static let nameKey = "name"
    private static let orderIndexKey = "orderIndex"
}
