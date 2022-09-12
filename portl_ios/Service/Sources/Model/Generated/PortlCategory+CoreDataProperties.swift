//
//  PortlCategory+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 7/4/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension PortlCategory {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PortlCategory> {
        return NSFetchRequest<PortlCategory>(entityName: "PortlCategory")
    }

    @NSManaged public var name: String
    @NSManaged public var display: String
	@NSManaged public var defaultSelected: Bool
	@NSManaged public var defaultIndex: Int64
}

