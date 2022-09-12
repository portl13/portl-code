//
//  Conversation+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension Conversation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Conversation> {
        return NSFetchRequest<Conversation>(entityName: "Conversation")
    }
	
	@NSManaged public var key: String
    @NSManaged public var overview: ConversationOverview?
    @NSManaged public var messages: NSSet?
	@NSManaged public var senders: NSSet?
}

// MARK: Generated accessors for messages
extension Conversation {

    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: ConversationMessage)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: ConversationMessage)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
	
	@objc(addSendersObject:)
	@NSManaged public func addToSenders(_ value: ConversationSender)
	
	@objc(removeSendersObject:)
	@NSManaged public func removeFromSenders(_ value: ConversationSender)
	
	@objc(addSenders:)
	@NSManaged public func addToSenders(_ values: NSSet)

	@objc(removeSenders:)
	@NSManaged public func removeFromSenders(_ values: NSSet)
}
