//
//  FirebaseLivefeed.swift
//  Portl
//
//  Created by Jeff Creed on 3/15/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

public struct FirebaseLivefeedObject: Decodable {
	public let date: String
	public let eventID: String?
	public let imageURL: String?
	public let message: String?
	public let objectType: String
	public let profileID: String
	public let messageKey: String?
	public let voteTotal: Int64?
	
	private enum CodingKeys: String, CodingKey {
		case date, message
		case eventID = "event_id"
		case imageURL = "image_url"
		case objectType = "type"
		case profileID = "profile_id"
		case messageKey = "message_key"
		case voteTotal = "vote_total"
	}
	
	func getType() -> ObjectType {
		return ObjectType(rawValue: objectType)!
	}
	
	public enum ObjectType: String {
		case share = "s"
		case going = "g"
		case interested = "i"
		case community = "c"
		case experience = "e"
	}
}
