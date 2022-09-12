//
//  Search+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/25/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension Search {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Search> {
        return NSFetchRequest<Search>(entityName: "Search")
    }

    @NSManaged public var pageSize: Int16
    @NSManaged public var totalCount: Int16
    @NSManaged public var searchPages: NSSet?

}

// MARK: Generated accessors for searchPages
extension Search {

    @objc(addSearchPagesObject:)
    @NSManaged public func addToSearchPages(_ value: SearchPage)

    @objc(removeSearchPagesObject:)
    @NSManaged public func removeFromSearchPages(_ value: SearchPage)

    @objc(addSearchPages:)
    @NSManaged public func addToSearchPages(_ values: NSSet)

    @objc(removeSearchPages:)
    @NSManaged public func removeFromSearchPages(_ values: NSSet)

}
