//
//  ConversationMessage+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CoreData
import APIService

extension ConversationMessage: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return ["key": values[messageKeyKey]!]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		key = values[ConversationMessage.messageKeyKey] as! String
		profileID = values[ConversationMessage.profileIDKey] as! String
		
		sent = (service as! FirebaseService).getFirebaseDate(fromString: values[ConversationMessage.sentKey] as! String)
		
		message = values[ConversationMessage.messageKey] as? String
		isHTML = values[ConversationMessage.isHTMLKey] as? Bool ?? false
		imageURL = values[ConversationMessage.imageURLKey] as? String
		imageHeightValue = values[ConversationMessage.imageHeightKey] as? NSNumber
		imageWidthValue = values[ConversationMessage.imageWidthKey] as? NSNumber
		eventIdentifier = values[ConversationMessage.eventIDKey] as? String
		videoURL = values[ConversationMessage.videoURLKey] as? String
		videoDuration = values[ConversationMessage.videoDurationKey] as? NSNumber
		voteTotal = values[ConversationMessage.voteTotalKey] as? NSNumber
	}
	
	public static let requiredKeys = [profileIDKey, sentKey, messageKeyKey]
	
	// MARK: Properties (Private Static Constant)
	
	private static let profileIDKey = "profile_id"
	private static let sentKey = "sent"
	private static let messageKey = "message"
	private static let isHTMLKey = "is_html"
	private static let imageURLKey = "image_url"
	private static let imageHeightKey = "image_height"
	private static let imageWidthKey = "image_width"
	private static let messageKeyKey = "message_key"
	private static let eventIDKey = "event_id"
	private static let videoURLKey = "video_url"
	private static let videoDurationKey = "video_duration"
	private static let voteTotalKey = "vote_total"
}
