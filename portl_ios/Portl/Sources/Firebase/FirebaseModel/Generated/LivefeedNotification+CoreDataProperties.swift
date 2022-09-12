//
//  LivefeedNotification+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/31/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension LivefeedNotification {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LivefeedNotification> {
        return NSFetchRequest<LivefeedNotification>(entityName: "LivefeedNotification")
    }

    @NSManaged public var date: NSDate
    @NSManaged public var eventID: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var message: String?
    @NSManaged public var notificationKey: String
    @NSManaged public var notificationTypeValue: String
    @NSManaged public var userID: String
    @NSManaged public var messageKey: String?
	@NSManaged public var replyThreadKey: String?
	@NSManaged public var markedForDeletion: Bool
    @NSManaged public var livefeeds: NSSet?
	@NSManaged public var videoURL: String?
	@NSManaged public var videoDuration: NSNumber?
	@NSManaged public var voteTotal: NSNumber?
}

// MARK: Generated accessors for livefeeds
extension LivefeedNotification {

    @objc(addLivefeedsObject:)
    @NSManaged public func addToLivefeeds(_ value: Livefeed)

    @objc(removeLivefeedsObject:)
    @NSManaged public func removeFromLivefeeds(_ value: Livefeed)

    @objc(addLivefeeds:)
    @NSManaged public func addToLivefeeds(_ values: NSSet)

    @objc(removeLivefeeds:)
    @NSManaged public func removeFromLivefeeds(_ values: NSSet)

}
