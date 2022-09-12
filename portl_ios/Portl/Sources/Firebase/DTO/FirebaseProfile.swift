//
//  FirebaseProfile.swift
//  Portl
//
//  Created by Jeff Creed on 3/15/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

public struct FirebaseProfile: Decodable {
	public let avatar: String?
	public let bio: String?
	public let birthDate: String?
	public let conversation: [String: ConversationInfo]?
	public let created: String
	public let email: String
	public let events: Events?
	public let friends: [String: String]?
	public let firstName: String?
	public let gender: String?
	public let interests: Array<[String: Bool]>?
	public let lastName: String?
	public let location: String?
	public let showJoined: Bool?
	public let uid: String
	public let unseenLivefeed: [String: String]?
	public let username: String
	public let website: String?
	public let zipcode: String?
	public let unreadMessages: [String: String]?
	public let following: Following?
	
	func getFirstNameLastName() -> String? {
		return [firstName, lastName].compactMap { $0 }.joined(separator: " ")
	}
	
	private enum CodingKeys: String, CodingKey {
		case avatar, bio, conversation, created, email, events, friends, gender, interests, location, uid, username, website, zipcode, following
		case birthDate  = "birth_date"
		case firstName = "first_name"
		case lastName = "last_name"
		case showJoined = "show_joined"
		case unseenLivefeed = "unseen_livefeed"
		case unreadMessages = "unread_messages"
	}
	
	public struct ConversationInfo: Decodable {
		public let notification: Bool
		public let hasNew: Bool
		public let archivedMessages: [String: Bool]?
		public let isArchived: Bool?
		
		private enum CodingKeys: String, CodingKey {
			case notification
			case archivedMessages = "archived_messages"
			case hasNew = "has_new"
			case isArchived = "is_archived"
		}
	}
	
	public struct Events: Decodable {
		public let going: [String: GoingData]?
		public let favorite: [String: EventActionData]?
		public let share: [String: String]?
		
		public struct GoingData: Decodable {
			public let actionDate: String
			public let status: String
			public let eventDate: String?
			
			private enum CodingKeys: String, CodingKey {
				case status
				case actionDate = "action_date"
				case eventDate = "event_date"
			}
			
			func goingStatus() -> FirebaseProfile.EventGoingStatus {
				switch status {
				case "g":
					return .going
				default:
					return .interested
				}
			}
			
			func toFirebaseData() -> [String : Any] {
				var data: [String : Any] = [:]
				data[CodingKeys.actionDate.stringValue] = actionDate
				data[CodingKeys.status.stringValue] = status
				if let eventDate = eventDate {
					data[CodingKeys.eventDate.stringValue] = eventDate
				}
				return data
			}
		}
		
		public struct EventActionData: Decodable {
			public let actionDate: String
			public let eventDate: String?
			
			private enum CodingKeys: String, CodingKey {
				case actionDate = "action_date"
				case eventDate = "event_date"
			}
			
			func toFirebaseData() -> [String: Any] {
				var data: [String : Any] = [:]
				data[CodingKeys.actionDate.stringValue] = actionDate
				data[CodingKeys.eventDate.stringValue] = eventDate
				return data
			}
		}
		
		func getFavoriteEventIDs() -> [String] {
			return favorite?.sorted(by: { (favorite, other) -> Bool in
				return favorite.value.actionDate > other.value.actionDate
			}).map({ (favorite) -> String in
				return favorite.key
			}) ?? []
		}
	}
	
	public struct Following: Decodable {
		public let artist: [String: Bool]?
		public let venue: [String: Bool]?
		
		func getArtistIDs() -> [String] {
			return artist?.map { $0.key } ?? []
		}
		
		func getVenueIDs() -> [String] {
			return venue?.map { $0.key } ?? []
		}
	}
	
	enum EventGoingStatus: Int {
		case none = 0
		case going
		case interested
	}
}




