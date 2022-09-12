//
//  SearchPage+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/25/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension SearchPage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SearchPage> {
        return NSFetchRequest<SearchPage>(entityName: "SearchPage")
    }

    @NSManaged public var pageIndex: Int16
    @NSManaged public var totalCount: Int16
    @NSManaged public var pageSize: Int16
    @NSManaged public var searchItems: NSSet?
    @NSManaged public var search: Search

}

// MARK: Generated accessors for searchItems
extension SearchPage {

    @objc(addSearchItemsObject:)
    @NSManaged public func addToSearchItems(_ value: SearchItem)

    @objc(removeSearchItemsObject:)
    @NSManaged public func removeFromSearchItems(_ value: SearchItem)

    @objc(addSearchItems:)
    @NSManaged public func addToSearchItems(_ values: NSSet)

    @objc(removeSearchItems:)
    @NSManaged public func removeFromSearchItems(_ values: NSSet)
}

