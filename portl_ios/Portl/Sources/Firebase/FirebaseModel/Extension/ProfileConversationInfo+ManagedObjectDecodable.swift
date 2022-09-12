//
//  ProfileConversationInfo+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import APIService

extension ProfileConversationInfo: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return [:]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		conversationKey = values[ProfileConversationInfo.conversationKeyKey] as! String
		notification = values[ProfileConversationInfo.notificationKey] as! Bool
		hasNew = values[ProfileConversationInfo.hasNewKey] as! Bool
		lastSeen = (values[ProfileConversationInfo.lastSeenKey] as? String).flatMap({ (dateString) -> NSDate in
			return (service as! FirebaseService).getFirebaseDate(fromString: dateString) as NSDate
		})
	}
	
	public static let requiredKeys = [notificationKey, hasNewKey, lastSeenKey, conversationKeyKey]
	
	private static let notificationKey = "notification"
	private static let hasNewKey = "has_new"
	private static let lastSeenKey = "last_seen"
	private static let conversationKeyKey = "conversation_key"
}
