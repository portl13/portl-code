//
//  FirebaseEvent.swift
//  Portl
//
//  Created by Jeff Creed on 3/21/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

public struct FirebaseEvent: Decodable {
	public let going: Dictionary<String, GoingData>?
	public let goingCount: Int?
	public let interestedCount: Int?
	
	private enum CodingKeys: String, CodingKey {
		case going
		case goingCount = "going_count"
		case interestedCount = "interested_count"
	}
	
	public struct GoingData: Decodable {
		public let status: String
		public let date: String
		
		func goingStatus() -> FirebaseProfile.EventGoingStatus {
			switch status {
			case "g":
				return .going
			default:
				return .interested
			}
		}
	}
	
	func goingIDs() -> Array<String> {
		if let keys = going?.keys {
			return Array(keys)
		} else {
			return []
		}
	}
}
