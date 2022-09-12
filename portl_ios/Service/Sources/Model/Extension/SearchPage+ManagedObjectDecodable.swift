//
//  SearchPage+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/14/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension SearchPage: ManagedObjectDecodable {
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [:]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        pageIndex = values[SearchPage.pageKey] as! Int16
        pageSize = values[SearchPage.pageSizeKey] as! Int16
        totalCount = values[SearchPage.totalCountKey] as! Int16
    }
        
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    
    public static let requiredKeys = [pageKey, pageSizeKey, totalCountKey]
    
    // MARK: Properties (Private Static Constant, From Superclass)
    
    private static let pageKey = "page"
    private static let pageSizeKey = "pageSize"
    private static let totalCountKey = "totalCount"
}
