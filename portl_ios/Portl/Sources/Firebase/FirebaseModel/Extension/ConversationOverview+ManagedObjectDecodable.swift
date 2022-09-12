//
//  ConversationOverview+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CoreData
import APIService

extension ConversationOverview: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return ["conversationKey": values[conversationKeyKey]!]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		
		conversationKey = values[ConversationOverview.conversationKeyKey] as! String
		messageCount = values[ConversationOverview.messageCountKey] as? Int64 ?? 0
		senderCount = values[ConversationOverview.senderCountKey] as! Int64
		commentCount = values[ConversationOverview.commentCountKey] as! Int64
		imageCount = values[ConversationOverview.imageCountKey] as! Int64
		firstMessage = values[ConversationOverview.messageCountKey] as? String
		lastMessage = values[ConversationOverview.lastMessageKey] as? String
		lastImageURL = values[ConversationOverview.lastImageURLKey] as? String
		lastVideoURL = values[ConversationOverview.lastVideoURLKey] as? String
		lastSender = values[ConversationOverview.lastSenderKey] as? String
		videoCount = (values[ConversationOverview.videoCountKey] as? Int64) ?? 0 // needs to be optional until next firebase migration
		self.lastMessageKey = values[ConversationOverview.lastMessageKeyKey] as? String
		
		if let activityDateString = values[ConversationOverview.lastActivityKey] as? String {
			let date = (service as! FirebaseService).getFirebaseDate(fromString: activityDateString)
			lastActivity = date
		}
	}
	
	public static let requiredKeys = [senderCountKey, commentCountKey, imageCountKey]
	
	// MARK: Properties (Private Static Constant)
	
	private static let messageCountKey = "message_count"
	private static let senderCountKey = "sender_count"
	private static let firstMessageKey = "first_message"
	private static let lastMessageKey = "last_message"
	private static let lastImageURLKey = "last_image_url"
	private static let lastVideoURLKey = "last_video_url"
	private static let lastSenderKey = "last_sender"
	private static let lastActivityKey = "last_activity"
	private static let imageCountKey = "image_count"
	private static let commentCountKey = "comment_count"
	private static let conversationKeyKey = "conversation_key"
	private static let lastMessageKeyKey = "last_message_key"
	private static let videoCountKey = "video_count"
}
