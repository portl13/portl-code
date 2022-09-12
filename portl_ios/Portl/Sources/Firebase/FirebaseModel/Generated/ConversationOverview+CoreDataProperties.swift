//
//  ConversationOverview+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ConversationOverview {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationOverview> {
        return NSFetchRequest<ConversationOverview>(entityName: "ConversationOverview")
    }

	@NSManaged public var conversationKey: String
    @NSManaged public var messageCount: Int64
    @NSManaged public var senderCount: Int64
    @NSManaged public var commentCount: Int64
    @NSManaged public var imageCount: Int64
    @NSManaged public var firstMessage: String?
    @NSManaged public var lastMessage: String?
    @NSManaged public var lastImageURL: String?
	@NSManaged public var lastVideoURL: String?
    @NSManaged public var lastSender: String?
    @NSManaged public var lastActivity: NSDate?
    @NSManaged public var conversation: Conversation?
	@NSManaged public var directProfile: Profile?
	@NSManaged public var lastMessageKey: String?
	@NSManaged public var videoCount: Int64
	
	public func getOtherProfileIDForDirectMessageConversationKey(authID: String) -> String? {
		guard conversationKey.starts(with: "d_") else {
			return nil
		}

		return conversationKey.split(separator: "_").map { String($0) }.dropFirst().filter { $0 != authID }.first
	}
}

