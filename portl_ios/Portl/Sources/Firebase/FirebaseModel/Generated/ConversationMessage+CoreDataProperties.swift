//
//  ConversationMessage+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ConversationMessage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationMessage> {
        return NSFetchRequest<ConversationMessage>(entityName: "ConversationMessage")
    }

    @NSManaged public var profileID: String
    @NSManaged public var sent: NSDate
    @NSManaged public var message: String?
    @NSManaged public var isHTML: Bool
    @NSManaged public var imageURL: String?
    @NSManaged public var imageHeightValue: NSNumber?
    @NSManaged public var imageWidthValue: NSNumber?
    @NSManaged public var key: String
    @NSManaged public var conversation: Conversation?
	@NSManaged public var eventIdentifier: String?
	@NSManaged public var videoURL: String?
	@NSManaged public var videoDuration: NSNumber?
	@NSManaged public var voteTotal: NSNumber?
}
