//
//  ProfileVote+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 2/4/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import APIService

extension ProfileVote: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		var attributes = ["messageKey": values[messageKeyKey]!]
		
		if let profileID = values[experienceProfileIDKey] {
			attributes["experienceProfileID"] = profileID
		} else if let conversationKey = values[conversationKeyKey] {
			attributes["conversationKey"] = conversationKey
		}
		
		return attributes
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		experienceProfileID = values[ProfileVote.experienceProfileIDKey] as? String
		conversationKey = values[ProfileVote.conversationKeyKey] as? String
		messageKey = values[ProfileVote.messageKeyKey] as! String
		value = values[ProfileVote.valueKey] as! Bool
	}
	
	public static let requiredKeys = [messageKeyKey]
	
	private static let experienceProfileIDKey = "experience_profile_id"
	private static let conversationKeyKey = "conversation_key"
	private static let messageKeyKey = "message_key"
	private static let valueKey = "value"
}

