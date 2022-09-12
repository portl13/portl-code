//
//  ProfileGoingData+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/2/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import APIService

extension ProfileGoingData: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return [:]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		eventID = values[ProfileGoingData.eventIDKey] as! String
		actionDate = (service as! FirebaseService).getFirebaseDate(fromString: values[ProfileGoingData.actionDateKey] as! String) as NSDate
		statusValue = values[ProfileGoingData.statusKey] as! String
		eventDate = (values[ProfileGoingData.eventDateKey] as? String).flatMap({ (dateString) -> NSDate? in
			(service as! FirebaseService).getFirebaseDate(fromString: dateString) as NSDate
		})
	}
	
	public static let requiredKeys = [eventIDKey, actionDateKey, statusKey]

	private static let eventIDKey = "event_id"
	private static let statusKey = "status"
	private static let actionDateKey = "action_date"
	private static let eventDateKey = "event_date"
}
