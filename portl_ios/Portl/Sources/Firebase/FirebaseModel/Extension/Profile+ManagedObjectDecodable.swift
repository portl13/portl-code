//
//  Profile+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import APIService

extension Profile: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return ["uid": values[uidKey]!]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		avatar = values[Profile.avatarKey] as? String
		bio = values[Profile.bioKey] as? String
		
		// TODO: birthDate = (values[Profile.birthDateKey] )
		
		conversations = (values[Profile.conversationKey] as? Dictionary<String, Any>).flatMap { (allConversationInfoValues) -> NSSet in
			let conversationObjects = NSMutableSet()
			
			for conversationValues in allConversationInfoValues {
				if var cv = conversationValues.value as? Dictionary<String, Any> {
					cv["conversation_key"] = conversationValues.key
					if let entity = try? service.managedObject(of: ProfileConversationInfo.self, forValues: cv, in: self.managedObjectContext!) {
						entity.profile = self
						conversationObjects.add(entity)
					}
				}
			}
			return conversationObjects
		}
		email = values[Profile.emailKey] as! String
		
		events = (values[Profile.eventsKey] as? Dictionary<String, Any>).flatMap { (allEventsValues) -> ProfileEvents? in
			return try? service.managedObject(of: ProfileEvents.self, forValues: allEventsValues, in: self.managedObjectContext!)
		}

		(friends as? Set<ProfileFriendData>)?.forEach { managedObjectContext?.delete($0) }
		
		friends = (values[Profile.friendsKey] as? Dictionary<String, String>).flatMap { (allFriendsValues) -> NSSet in
			let friendsObjects = NSMutableSet()

			for friendValues in allFriendsValues {
				let fv = ["friend_profile_id": friendValues.key, "since_date": friendValues.value]
				if let entity = try? service.managedObject(of: ProfileFriendData.self, forValues: fv, in: self.managedObjectContext!) {
					friendsObjects.add(entity)
				}
			}
			return friendsObjects
		}
		
		firstName = values[Profile.firstNameKey] as? String
		genderValue = values[Profile.genderKey] as? String
		
		// TODO: interests =
		
		lastName = values[Profile.lastNameKey] as? String
		showJoined = values[Profile.showJoinedKey] as? Bool ?? true
		uid = values[Profile.uidKey] as! String
		
		// TODO: unseen livefeed
		
		username = values[Profile.usernameKey] as! String
		website = values[Profile.websiteKey] as? String
		zipcode = values[Profile.zipcodeKey] as? String
	}
	
	public static let requiredKeys = [uidKey]

	private static let avatarKey = "avatar"
	private static let bioKey = "bio"
	private static let birthDateKey = "birth_date"
	private static let conversationKey = "conversation"
	private static let emailKey = "email"
	private static let eventsKey = "events"
	private static let friendsKey = "friends"
	private static let firstNameKey = "first_name"
	private static let genderKey = "gender"
	private static let interestsKey = "interests"
	private static let lastNameKey = "last_name"
	private static let showJoinedKey = "show_joined"
	private static let uidKey = "uid"
	private static let unseenLivefeedKey = "unseen_livefeed"
	private static let usernameKey = "username"
	private static let websiteKey = "website"
	private static let zipcodeKey = "zipcode"
}
