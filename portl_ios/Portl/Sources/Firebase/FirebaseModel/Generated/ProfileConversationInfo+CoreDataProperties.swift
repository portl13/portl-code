//
//  ProfileConversationInfo+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ProfileConversationInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProfileConversationInfo> {
        return NSFetchRequest<ProfileConversationInfo>(entityName: "ProfileConversationInfo")
    }

    @NSManaged public var notification: Bool
    @NSManaged public var hasNew: Bool
    @NSManaged public var lastSeen: NSDate?
    @NSManaged public var conversationKey: String
    @NSManaged public var profile: Profile

}
