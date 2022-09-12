//
//  ProfileGoingData+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ProfileGoingData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProfileGoingData> {
        return NSFetchRequest<ProfileGoingData>(entityName: "ProfileGoingData")
    }

    @NSManaged public var actionDate: NSDate
    @NSManaged public var eventDate: NSDate?
    @NSManaged public var statusValue: String
    @NSManaged public var eventID: String
    @NSManaged public var profileEvents: ProfileEvents?
}
