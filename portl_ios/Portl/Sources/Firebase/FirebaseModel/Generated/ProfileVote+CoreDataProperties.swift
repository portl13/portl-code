//
//  ProfileVote+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 2/4/20.
//  Copyright © 2020 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ProfileVote {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProfileVote> {
        return NSFetchRequest<ProfileVote>(entityName: "ProfileVote")
    }

    @NSManaged public var conversationKey: String?
    @NSManaged public var experienceProfileID: String?
    @NSManaged public var messageKey: String
	@NSManaged public var value: Bool
    @NSManaged public var profile: Profile?
}
