//
//  ConversationSender+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CoreData
import APIService

extension ConversationSender: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return [:]
	}

	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		// should be one entry in dictionary
		guard let senderValues = values.first else {
			return
		}
		
		profileID = senderValues.key
		// todo: need to fix date in firebase
		//lastActivity = ISO8601DateFormatter().date(from: senderValues.value as! String)! as NSDate
	}
	
	public static let requiredKeys: [String] = []
}
