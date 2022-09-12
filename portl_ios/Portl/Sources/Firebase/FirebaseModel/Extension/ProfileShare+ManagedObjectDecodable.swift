//
//  ProfileShare+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/3/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import APIService

extension ProfileShare: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return [:]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		eventID = values[ProfileShare.eventIDKey] as! String
		actionDate = (service as! FirebaseService).getFirebaseDate(fromString: values[ProfileShare.actionDateKey] as! String) as NSDate
	}
	
	public static let requiredKeys = [eventIDKey, actionDateKey]

	private static let eventIDKey = "event_id"
	private static let actionDateKey = "action_date"
}
