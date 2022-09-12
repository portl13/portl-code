//
//  ConversationSender+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ConversationSender {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationSender> {
        return NSFetchRequest<ConversationSender>(entityName: "ConversationSender")
    }

    @NSManaged public var profileID: String
    @NSManaged public var lastActivity: NSDate
    @NSManaged public var conversation: Conversation?

}
