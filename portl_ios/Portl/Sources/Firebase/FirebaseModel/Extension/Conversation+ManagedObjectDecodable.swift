//
//  Conversation+ManagedObjectDecodable.swift
//  Service
//
//  Created by Jeff Creed on 4/29/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CoreData
import APIService

extension Conversation: ManagedObjectDecodable {
	public static func identifyingAttributes(fromValues values: Dictionary<String, Any>) -> Dictionary<String, Any> {
		return ["key": values[conversationKeyKey]!]
	}

	public func setAttributes(forValues values: Dictionary<String, Any>, service: ManagedObjectDecodableService) throws {
		key = values[Conversation.conversationKeyKey] as! String
		
		let senderObjects = NSMutableSet()
		if let allSendersValues = values[Conversation.sendersKey] as? Dictionary<String, Any> {
			for senderValues in allSendersValues {
				let sender = try service.managedObject(of: ConversationSender.self, forValues: Dictionary<String, Any>(dictionaryLiteral: senderValues), in: self.managedObjectContext!)
				senderObjects.add(sender)
			}
		}
		senders = senderObjects
		
		if var overviewValues = values[Conversation.overviewKey] as? Dictionary<String, Any> {
			overviewValues[Conversation.conversationKeyKey] = values[Conversation.conversationKeyKey] as! String
			overview = try service.managedObject(of: ConversationOverview.self, forValues: overviewValues, in: self.managedObjectContext!)
		}
		
		let messageObjects = NSMutableSet()
		if let allMessagesValues = values[Conversation.messagesKey] as? Dictionary<String, Any> {
			for messageValues in allMessagesValues {
				var modifiedMessageValues = messageValues.value as! Dictionary<String, Any>
				modifiedMessageValues["message_key"] = messageValues.key
				let message = try service.managedObject(of: ConversationMessage.self, forValues: modifiedMessageValues, in: self.managedObjectContext!)
				message.conversation = self
				messageObjects.add(message)
			}
		}
		
		messages = messageObjects
	}
	
	public static let requiredKeys = [Conversation.conversationKeyKey]
	
	// MARK: Properties (Private Static Constant)
	
	private static let conversationKeyKey = "conversation_key"
	private static let sendersKey = "senders"
	private static let overviewKey = "overview"
	private static let messagesKey = "messages"
}
