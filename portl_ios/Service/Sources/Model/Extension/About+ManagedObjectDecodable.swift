//
//  About+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 3/31/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension About: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [:]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        markupType = values[About.markupTypeKey] as! String
        value = values[About.valueKey] as! String
    }
    
    public func setAttributes(forValues values: Dictionary<String, Any>) throws {}
    
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    public static let requiredKeys = [markupTypeKey, valueKey]
    
    // MARK: Properties (Private Static Constant)
    private static let markupTypeKey = "markupType"
    private static let valueKey = "value"
}
