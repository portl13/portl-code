//
//  PortlCategory+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 7/4/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension PortlCategory: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [nameKey: values[nameKey]!]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        name = values[PortlCategory.nameKey] as! String
		display = values[PortlCategory.displayKey] as! String
		defaultIndex = values[PortlCategory.indexKey] as! Int64
		defaultSelected = values[PortlCategory.selectedKey] as? Bool ?? false
    }
        
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    
    public static let requiredKeys = [nameKey, displayKey, indexKey]
    
    // MARK: Properties (Private Static Constant)
    
    private static let nameKey = "name"
    private static let displayKey = "display"
	private static let indexKey = "idx"
	private static let selectedKey = "selected"
}
