//
//  ProfileShare+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ProfileShare {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProfileShare> {
        return NSFetchRequest<ProfileShare>(entityName: "ProfileShare")
    }

    @NSManaged public var eventID: String
    @NSManaged public var actionDate: NSDate
    @NSManaged public var profileEvents: ProfileEvents

}
