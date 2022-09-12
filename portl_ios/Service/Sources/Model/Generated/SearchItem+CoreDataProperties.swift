//
//  SearchItem+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/25/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension SearchItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SearchItem> {
        return NSFetchRequest<SearchItem>(entityName: "SearchItem")
    }

    @NSManaged public var searchPages: NSSet
}

// MARK: Generated accessors for searchPages
extension SearchItem {
	
	@objc(addSearchPagesObject:)
	@NSManaged public func addToSearchPages(_ value: SearchPage)
	
	@objc(removeSearchPagesObject:)
	@NSManaged public func removeFromSearchPages(_ value: SearchPage)
	
	@objc(addSearchPages:)
	@NSManaged public func addToSearchPages(_ values: NSSet)
	
	@objc(removeSearchPages:)
	@NSManaged public func removeFromSearchPages(_ values: NSSet)
}
