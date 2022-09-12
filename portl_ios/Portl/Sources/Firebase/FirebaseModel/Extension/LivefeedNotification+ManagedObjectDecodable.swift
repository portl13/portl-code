//
//  LivefeedNotification_ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import APIService

extension LivefeedNotification: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return ["notificationKey": values[notificationKeyKey]!]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		notificationKey = values[LivefeedNotification.notificationKeyKey] as! String
		date = (service as! FirebaseService).getFirebaseDate(fromString: values[LivefeedNotification.dateKey] as! String)
		eventID = values[LivefeedNotification.eventIDKey] as? String
		notificationTypeValue = values[LivefeedNotification.notificationTypeKey] as! String
		userID = values[LivefeedNotification.userIDKey] as! String
		imageURL = values[LivefeedNotification.imageURLKey] as? String
		message = values[LivefeedNotification.messageKey] as? String
		messageKey = values[LivefeedNotification.messageKeyKey] as? String
		replyThreadKey = values[LivefeedNotification.replyThreadKey] as? String
		videoURL = values[LivefeedNotification.videoURLKey] as? String
		videoDuration = values[LivefeedNotification.videDurationKey] as? NSNumber
		voteTotal = values[LivefeedNotification.voteTotalKey] as? NSNumber
	}
	
	public static let requiredKeys = [dateKey, notificationTypeKey, userIDKey, notificationKeyKey]
	
	private static let notificationKeyKey = "notification_key"
	private static let dateKey = "date"
	private static let eventIDKey = "event_id"
	private static let imageURLKey = "image_url"
	private static let notificationTypeKey = "type"
	private static let userIDKey = "profile_id"
	private static let messageKey = "message"
	private static let messageKeyKey = "message_key"
	private static let replyThreadKey = "reply_thread_key"
	private static let videoURLKey = "video_url"
	private static let videDurationKey = "video_duration"
	private static let voteTotalKey = "vote_total"
}


