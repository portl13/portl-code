//
//  Livefeed+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import APIService

extension Livefeed: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return ["userID": values[userIDKey]!]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		userID = values[Livefeed.userIDKey] as! String
		var allLivefeedNotificationValues = values
		allLivefeedNotificationValues.removeValue(forKey: Livefeed.userIDKey)
		
		var notificationEntities = Set<LivefeedNotification>()
		var entityKeys = Set<String>()
		try allLivefeedNotificationValues.forEach { (arg0) in
			let (key, value) = arg0
			if var livefeedNotificationValues = value as? Dictionary<String, Any> {
				livefeedNotificationValues["notification_key"] = key
				let notification = try service.managedObject(of: LivefeedNotification.self, forValues: livefeedNotificationValues, in: self.managedObjectContext!)
				notificationEntities.insert(notification)
				entityKeys.insert(key)
			}
		}
		
		(notifications as? Set<LivefeedNotification>)?.forEach({ (notification) in
			if !entityKeys.contains(notification.notificationKey) {
				if notification.livefeeds?.count ?? 0 > 1 {
					notification.removeFromLivefeeds(self)
				} else {
					self.managedObjectContext!.delete(notification)
				}
			}
		})

		notifications = notificationEntities as NSSet
	}
	
	public static let requiredKeys = [ userIDKey ]
	
	private static let userIDKey = "user_id"
}
