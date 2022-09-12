//
//  FirebaseDataProviding.swift
//  Portl
//
//  Created by Jeff Creed on 5/13/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import Foundation
import CoreData

public protocol FirebaseDataProviding {
	func getDirectConversationOverviews(forProfileID profileID: String, completion: @escaping (Error?) -> Void)
	func getConversation(withKey conversationKey: String, archivedMessageKeys: [String]?, completion: @escaping (Error?) -> Void)
	func getConversationMessages(withConversationAndMessageKeys conversationAndMessageKeys: [(conversationKey: String, messageKey: String)], completion: @escaping (Error?) -> Void)
	func getConversationOverviews(withConversationKeys conversationKeys: [String], completion: @escaping (Error?) -> Void)
	func getProfile(withProfileID profileID: String, forConversationKey conversationKey: String, completion: @escaping (Error?, Profile?) -> Void, withContext context: NSManagedObjectContext?)
	func getProfiles(withProfileIDs profileIDs: [String], completion: @escaping (Error?) -> Void)
	func getFriendProfiles(forUserID userID: String, withCompletion completion: @escaping ([String], Error?) -> Void)
	func getKeyForFirstMessageOfConversation(withKey conversationKey: String) -> String?
	func getLivefeed(forUserID userID: String, maxNotifications: Int, isForProfilePage: Bool, completion: @escaping (NSManagedObjectID?, Error?) -> Void)
	func deleteLivefeedNotification(_ notification: LivefeedNotification)
	func deleteConversationOverview(_ overview: ConversationOverview)
	func deleteLivefeedNotificationForCommunitMessage(withEventID eventID: String, andMessageKey messageKey: String)
	func deleteLivefeedNotificationForExperience(withExperienceKey experienceKey: String)
	func deleteLivefeedNotificationForReply(withReplyThreadKey replyThreadKey: String, andMessageKey messageKey: String)
	func removeConversationHandle(forConversationWithKey conversationKey: String)
	func getConversationMessage(forConversationKey conversationKey: String, andMessageKey messageKey: String, completion: @escaping (ConversationMessage?) -> Void)
	func getExperience(forProfileID profileID: String, andExperienceKey experienceKey: String, completion: @escaping (ConversationMessage?) -> Void)
	
	func fetch(conversationWithKey conversationKey: String) -> Conversation?
	func fetchedResultsControllerForDirectConversationOverviews(forProfileID profileID: String, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<ConversationOverview>?
	func fetchedResultsController(forMessagesWithConversationKey conversationKey: String, delegate: NSFetchedResultsControllerDelegate, ascending: Bool) -> NSFetchedResultsController<ConversationMessage>?
	func fetchedResultsController(forMessagesWithKeys messageKeys: [String], delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<ConversationMessage>?
	func fetchedResultsControllerForConversationOverviews(withConversationKeys conversationKeys: [String], delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<ConversationOverview>?
	func fetchedResultsControllerForProfiles(withIDs profileIDs: [String], delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Profile>?
	func fetchedResultsController(forLivefeedWithObjectID managedObjectID: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<LivefeedNotification>?

	func clearPersonalData()
}
