//
//  ProfileFriendData+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import APIService

extension ProfileFriendData: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return [:]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		friendProfileID = values[ProfileFriendData.friendProfileIDKey] as! String
		sinceDate = (service as! FirebaseService).getFirebaseDate(fromString: (values[ProfileFriendData.sinceDateKey] as! String)) as NSDate
	}
	
	public static let requiredKeys = [friendProfileIDKey, sinceDateKey]
	
	private static let friendProfileIDKey = "friend_profile_id"
	private static let sinceDateKey = "since_date"
}
