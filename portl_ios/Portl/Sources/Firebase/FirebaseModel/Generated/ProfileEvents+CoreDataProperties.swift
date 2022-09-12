//
//  ProfileEvents+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ProfileEvents {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProfileEvents> {
        return NSFetchRequest<ProfileEvents>(entityName: "ProfileEvents")
    }

    @NSManaged public var profile: Profile?
    @NSManaged public var going: NSSet?
    @NSManaged public var favorites: NSSet?
	@NSManaged public var shares: NSSet?
}

// MARK: Generated accessors for going
extension ProfileEvents {

    @objc(addGoingObject:)
    @NSManaged public func addToGoing(_ value: ProfileGoingData)

    @objc(removeGoingObject:)
    @NSManaged public func removeFromGoing(_ value: ProfileGoingData)

    @objc(addGoing:)
    @NSManaged public func addToGoing(_ values: NSSet)

    @objc(removeGoing:)
    @NSManaged public func removeFromGoing(_ values: NSSet)

}

// MARK: Generated accessors for favorites
extension ProfileEvents {

    @objc(addFavoritesObject:)
    @NSManaged public func addToFavorites(_ value: ProfileFavoriteData)

    @objc(removeFavoritesObject:)
    @NSManaged public func removeFromFavorites(_ value: ProfileFavoriteData)

    @objc(addFavorites:)
    @NSManaged public func addToFavorites(_ values: NSSet)

    @objc(removeFavorites:)
    @NSManaged public func removeFromFavorites(_ values: NSSet)

}

// MARK: Generated accessors for shares
extension ProfileEvents {
	
	@objc(addSharesObject:)
	@NSManaged public func addToShares(_ value: ProfileShare)
	
	@objc(removeSharesObject:)
	@NSManaged public func removeFromShares(_ value: ProfileShare)
	
	@objc(addShares:)
	@NSManaged public func addToShares(_ values: NSSet)
	
	@objc(removeShares:)
	@NSManaged public func removeFromShares(_ values: NSSet)
	
}

