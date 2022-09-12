//
//  KeywordSearch+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension KeywordSearch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<KeywordSearch> {
        return NSFetchRequest<KeywordSearch>(entityName: "KeywordSearch")
    }

    @NSManaged public var keyword: String

}
