//
//  ProfileFavoriteData+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ProfileFavoriteData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProfileFavoriteData> {
        return NSFetchRequest<ProfileFavoriteData>(entityName: "ProfileFavoriteData")
    }

    @NSManaged public var eventID: String
    @NSManaged public var actionDate: NSDate
    @NSManaged public var eventDate: NSDate?
    @NSManaged public var profileEvents: ProfileEvents

}
