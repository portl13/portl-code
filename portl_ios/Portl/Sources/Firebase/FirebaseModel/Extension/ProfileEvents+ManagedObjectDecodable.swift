//
//  ProfileEvents+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 5/2/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import APIService

extension ProfileEvents: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return [:]
	}
	
	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		
		if let allGoingValues = values[ProfileEvents.goingKey] as? Dictionary<String, Any> {
			let goingObjects = NSMutableSet()

			for goingValues in allGoingValues {
				if var gv = goingValues.value as? Dictionary<String, Any> {
					gv["event_id"] = goingValues.key
					if let entity = try? service.managedObject(of: ProfileGoingData.self, forValues: gv, in: self.managedObjectContext!) {
						entity.profileEvents = self
						goingObjects.add(entity)
					}
				}
			}
			
			going = goingObjects
		}
		
		
		if let allShareValues = values[ProfileEvents.shareKey] as? Dictionary<String, String> {
			let shareObjects = NSMutableSet()

			for shareValues in allShareValues {
				let sv = ["event_id": shareValues.value, "action_date": shareValues.key]
				if let entity = try? service.managedObject(of: ProfileShare.self, forValues: sv, in: self.managedObjectContext!) {
					entity.profileEvents = self
					shareObjects.add(entity)
				}
			}
			
			shares = shareObjects
		}
		
		
		
		if let allFavoriteValues = values[ProfileEvents.favoriteKey] as? Dictionary<String, Any> {
			let favoriteObjects = NSMutableSet()
			
			for favoriteValues in allFavoriteValues {
				if var fv = favoriteValues.value as? Dictionary<String, Any> {
					fv["event_id"] = favoriteValues.key
					if let entity = try? service.managedObject(of: ProfileFavoriteData.self, forValues: fv, in: self.managedObjectContext!) {
						entity.profileEvents = self
						favoriteObjects.add(entity)
					}
				}
			}
			
			favorites = favoriteObjects
		}
	}
	
	public static let requiredKeys = [""]
	
	private static let goingKey = "going"
	private static let favoriteKey = "favorite"
	private static let shareKey = "share"
}
