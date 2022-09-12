//
//  Identifiable+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/8/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension Identifiable {
    public static func predicateForCacheLookup(identifier: String) -> NSPredicate {
        return NSPredicate(format: "identifier == %@", identifier)
    }
    
    @NSManaged public var identifier: String
}
