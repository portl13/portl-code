//
//  ProfileFavoriteData+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import APIService

extension ProfileFavoriteData: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return [:]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		eventID = values[ProfileFavoriteData.eventIDKey] as! String
		actionDate = ISO8601DateFormatter().date(from: values[ProfileFavoriteData.actionDateKey] as! String)! as NSDate
		eventDate = (values[ProfileFavoriteData.eventDateKey] as? String).flatMap({ (dateString) -> NSDate? in
			(service as! FirebaseService).getFirebaseDate(fromString: dateString) as NSDate
		})
	}
	
	public static let requiredKeys = [eventIDKey, actionDateKey]
	
	private static let eventIDKey = "event_id"
	private static let actionDateKey = "action_date"
	private static let eventDateKey = "event_date"
}
