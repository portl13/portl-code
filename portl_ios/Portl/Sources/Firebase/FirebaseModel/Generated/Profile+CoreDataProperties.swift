//
//  Profile+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension Profile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile")
    }

    @NSManaged public var avatar: String?
    @NSManaged public var bio: String?
    @NSManaged public var birthDate: NSDate?
    @NSManaged public var email: String
    @NSManaged public var firstName: String?
    @NSManaged public var genderValue: String?
    @NSManaged public var lastName: String?
    @NSManaged public var showJoined: Bool
    @NSManaged public var uid: String
    @NSManaged public var username: String
    @NSManaged public var website: String?
    @NSManaged public var zipcode: String?
    @NSManaged public var conversations: NSSet?
    @NSManaged public var events: ProfileEvents?
	@NSManaged public var friends: NSSet?

	public func getFirstNameLastName() -> String? {
		return [firstName, lastName].compactMap { $0 }.joined(separator: " ")
	}
}

// MARK: Generated accessors for conversations
extension Profile {

    @objc(addConversationsObject:)
    @NSManaged public func addToConversations(_ value: ProfileConversationInfo)

    @objc(removeConversationsObject:)
    @NSManaged public func removeFromConversations(_ value: ProfileConversationInfo)

    @objc(addConversations:)
    @NSManaged public func addToConversations(_ values: NSSet)

    @objc(removeConversations:)
    @NSManaged public func removeFromConversations(_ values: NSSet)

}

// MARK: Generated accessors for friends
extension Profile {
	
	@objc(addFriendsObject:)
	@NSManaged public func addToFriends(_ value: ProfileFriendData)
	
	@objc(removeFriendsObject:)
	@NSManaged public func removeFromFriends(_ value: ProfileFriendData)
	
	@objc(addFriends:)
	@NSManaged public func addToFriends(_ values: NSSet)
	
	@objc(removeFriends:)
	@NSManaged public func removeFromFriends(_ values: NSSet)
	
}

// MARK: Generated accessors for conversationOverviews
extension Profile {
	
	@objc(addConversationOverviewsObject:)
	@NSManaged public func addToConversationOverviews(_ value: ConversationOverview)
	
	@objc(removeConversationOverviewsObject:)
	@NSManaged public func removeFromConversationOverviews(_ value: ConversationOverview)
	
	@objc(addConversationOVerviews:)
	@NSManaged public func addToConversationOverviews(_ values: NSSet)
	
	@objc(removeConversationOverviews:)
	@NSManaged public func removeFromConversationOverviews(_ values: NSSet)
	
}
