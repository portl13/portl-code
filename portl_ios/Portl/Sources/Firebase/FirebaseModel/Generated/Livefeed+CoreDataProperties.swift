//
//  Livefeed+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension Livefeed {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Livefeed> {
        return NSFetchRequest<Livefeed>(entityName: "Livefeed")
    }

    @NSManaged public var userID: String
    @NSManaged public var notifications: NSSet?

}

// MARK: Generated accessors for notifications
extension Livefeed {

    @objc(addNotificationsObject:)
    @NSManaged public func addToNotifications(_ value: LivefeedNotification)

    @objc(removeNotificationsObject:)
    @NSManaged public func removeFromNotifications(_ value: LivefeedNotification)

    @objc(addNotifications:)
    @NSManaged public func addToNotifications(_ values: NSSet)

    @objc(removeNotifications:)
    @NSManaged public func removeFromNotifications(_ values: NSSet)

}
