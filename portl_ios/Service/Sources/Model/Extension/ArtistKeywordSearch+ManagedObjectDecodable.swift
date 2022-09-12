//
//  ArtistKeywordSearch+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import APIService

extension ArtistKeywordSearch: ManagedObjectDecodable {
    public static func predicateForCacheLookup(keyword: String, pageSize: Int) -> NSPredicate {
        let formatString = "keyword == %@ AND pageSize == %@"
        let formatValues: [Any] = [keyword, pageSize as NSNumber]
        return NSPredicate(format: formatString, argumentArray: formatValues)
    }
    
    public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
        return [keywordKey: values[keywordKey]!, pageSizeKey: values[pageSizeKey]!, totalCountKey: values[totalCountKey]!]
    }
    
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
        timestamp = NSDate()
        keyword = values[ArtistKeywordSearch.keywordKey] as! String
        pageSize = values[ArtistKeywordSearch.pageSizeKey] as! Int16
        totalCount = values[ArtistKeywordSearch.totalCountKey] as! Int16
        
        let page = try service.managedObject(of: SearchPage.self, forValues: values, in: self.managedObjectContext!)
        page.search = self
        
        for var itemValues in (values[ArtistKeywordSearch.itemsKey] as? Array<Dictionary<String, Any>>) ?? [] {
			let artistValues = itemValues[ArtistKeywordSearchItem.artistKey] as! Dictionary<String, Any>
			let artistIdentifier = artistValues[PortlArtist.idKey] as! String
			itemValues[ArtistKeywordSearchItem.artistIdentifierKey] = artistIdentifier

            let item = try service.managedObject(of: ArtistKeywordSearchItem.self, forValues: itemValues, in: self.managedObjectContext!)
			item.addToSearchPages(page)
        }
    }
	
    // MARK: Properties (Static Constant, ManagedObjectDecodable)
    public static let requiredKeys = [keywordKey, pageSizeKey, totalCountKey, itemsKey]
    
    // MARK: Properties (Private Static Constant)
    private static let keywordKey = "keyword"
    
    // MARK: Properties (Private Static Constant, From Superclass)
    private static let pageKey = "page"
    private static let pageSizeKey = "pageSize"
    private static let totalCountKey = "totalCount"
    private static let itemsKey = "items"
}

