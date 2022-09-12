//
//  FirebaseConversation.swift
//  Portl
//
//  Created by Jeff Creed on 3/21/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

public struct FirebaseConversation: Decodable {
	public let senders: [String : String]?
	public let overview: Overview?
	public let messages: [String : Message]?
	
	public struct Overview: Decodable {
		public let messageCount: Int
		public let senderCount: Int
		public let commentCount: Int
		public let imageCount: Int
		public let firstMessage: String?
		public let lastMessage: String?
		public let lastImageURL: String?
		public let lastVideoURL: String?
		public let lastSender: String?
		public let lastActivity: String?
		public let videoCount: Int?
		
		private enum CodingKeys: String, CodingKey {
			case messageCount = "message_count"
			case senderCount = "sender_count"
			case firstMessage = "first_message"
			case lastMessage = "last_message"
			case lastImageURL = "last_image_url"
			case lastVideoURL = "last_video_url"
			case lastSender = "last_sender"
			case lastActivity = "last_activity"
			case imageCount = "image_count"
			case commentCount = "comment_count"
			case videoCount = "video_count"
		}
	}
	
	public struct Message: Decodable {
		public let profileID: String
		public let sent: String
		public let message: String?
		public let isHTML: Bool
		public let imageURL: String?
		public let imageHeight: CGFloat?
		public let imageWidth: CGFloat?
		public let eventID: String?
		public let eventTitle: String?
		public let videoURL: String?
		public let videoDuration: Double?
		public let voteTotal: Int64?
		
		private enum CodingKeys: String, CodingKey {
			case sent, message
			case profileID = "profile_id"
			case isHTML = "is_html"
			case imageURL = "image_url"
			case imageHeight = "image_height"
			case imageWidth = "image_width"
			case eventID = "event_id"
			case eventTitle = "event_title"
			case videoURL = "video_url"
			case videoDuration = "video_duration"
			case voteTotal = "vote_total"
		}
		
		func toFirebaseData() -> [String : Any] {
			var data: [String : Any] = [:]
			data[CodingKeys.profileID.stringValue] = profileID
			data[CodingKeys.sent.stringValue] = sent
			if let message = message {
				data[CodingKeys.message.stringValue] = message
			}
			data[CodingKeys.isHTML.stringValue] = isHTML
			if let imageURL = imageURL {
				data[CodingKeys.imageURL.stringValue] = imageURL
			}
			if let imageHeight = imageHeight {
				data[CodingKeys.imageHeight.stringValue] = imageHeight
			}
			if let imageWidth = imageWidth {
				data[CodingKeys.imageWidth.stringValue] = imageWidth
			}
			if let eventID = eventID {
				data[CodingKeys.eventID.stringValue] = eventID
			}
			if let eventTitle = eventTitle {
				data[CodingKeys.eventTitle.stringValue] = eventTitle
			}
			if let videoURL = videoURL {
				data[CodingKeys.videoURL.stringValue] = videoURL
			}
			if let videoDuration = videoDuration {
				data[CodingKeys.videoDuration.stringValue] = videoDuration
			}
			if let voteTotal = voteTotal {
				data[CodingKeys.voteTotal.stringValue] = voteTotal
			}
			return data
		}
	}
}
