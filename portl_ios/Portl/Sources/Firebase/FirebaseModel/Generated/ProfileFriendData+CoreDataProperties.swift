//
//  ProfileFriendData+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ProfileFriendData {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProfileFriendData> {
        return NSFetchRequest<ProfileFriendData>(entityName: "ProfileFriendData")
    }

    @NSManaged public var friendProfileID: String
    @NSManaged public var sinceDate: NSDate?
    @NSManaged public var profile: Profile?

}
