//
//  FirebaseService.swift
//  Portl
//
//  Created by Jeff Creed on 5/13/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import Foundation
import CoreData
import RxSwift
import CSkyUtil
import Firebase
import APIService

protocol ProvidesFirebaseDateFormatter {
	func getFirebaseDate(fromString string: String) -> NSDate
}

class FirebaseService: BaseCoreDataService, FirebaseDataProviding {
	func clearPersonalData() {
		conversationHandles.forEach { (arg0) in
			let (key, handle) = arg0
			self.conversationReferences[key]?.removeObserver(withHandle: handle)
		}
		conversationOverviewHandles.forEach { (arg0) in
			let (key, handle) = arg0
			self.conversationOverviewReferences[key]?.removeObserver(withHandle: handle)
		}
		
		conversationProfileHandles.forEach { (arg0) in
			let (key, handle) = arg0
			self.conversationProfileReferences[key]?.removeObserver(withHandle: handle)
		}

		deleteAllObjects(Conversation.entity().name!)
		deleteAllObjects(ConversationOverview.entity().name!)
		deleteAllObjects(Profile.entity().name!)
		deleteAllObjects(Livefeed.entity().name!)

		try? persistentContainer.viewContext.save()
	}
	
	func removeConversationHandle(forConversationWithKey conversationKey: String) {
		if let conversationHandle = conversationHandles[conversationKey] {
			conversationReferences[conversationKey]?.removeObserver(withHandle: conversationHandle)
		}
	}
	
	private func deleteAllObjects(_ entity:String) {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
		fetchRequest.returnsObjectsAsFaults = false
		do {
			let results = try persistentContainer.viewContext.fetch(fetchRequest)
			for object in results {
				guard let objectData = object as? NSManagedObject else {continue}
				persistentContainer.viewContext.delete(objectData)
			}
		} catch let error {
			print("Delete all data in \(entity) error :", error)
		}
	}

	
	// MARK: FIREBASE DATA
	
	private func remove(entities: Set<NSManagedObject>, fromContext context: NSManagedObjectContext, completion: @escaping (Error?) -> Void) {
		entities.forEach { (entity) in
			context.delete(entity)
		}
		
		do {
			try context.save()
		} catch let e {
			print(e)
			context.rollback()
			completion(e)
			return
		}
		
		completion(nil)
	}
	
	func getDirectConversationOverviews(forProfileID profileID: String, completion: @escaping (Error?) -> Void) {
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

		let fetchRequest: NSFetchRequest<ConversationOverview> = ConversationOverview.fetchRequest()
		var currentOverviews = Array<ConversationOverview>()
		var toRemove = Set<ConversationOverview>()
		
		do {
			currentOverviews = try context.fetch(fetchRequest)
			toRemove = Set(currentOverviews)
		} catch {
			print("Error finding existing conversation overviews")
		}

		let reference = Database.database().reference().child("v2/profile").child(profileID).child("conversation")
		if let existingHandle = profileConversationOverviewsHandle {
			profileConversationOverviewsReference?.removeObserver(withHandle: existingHandle)
		}
		profileConversationOverviewsReference = reference
		
		profileConversationOverviewsHandle = reference.observe(.value) { (overviewsSnapshot) in
			if overviewsSnapshot.exists()  {
				for overview in (overviewsSnapshot.children.allObjects as! [DataSnapshot]) {
					let conversationKey = overview.key
				
					guard conversationKey.starts(with: "d_") else {
						continue
					}
					
					guard let conversationValues = overview.value as? Dictionary<String, Any> else {
						continue
					}
					
					let isArchived = conversationValues["is_archived"] as? Bool ?? false
					
					let overviewReference = Database.database().reference().child("v2/conversation").child(conversationKey).child("overview")
					self.conversationOverviewReferences[conversationKey] = overviewReference
					
					if let existingHandle = self.conversationOverviewHandles[conversationKey] {
						overviewReference.removeObserver(withHandle: existingHandle)
					}
					
					if !isArchived {
						self.conversationOverviewHandles[conversationKey] = overviewReference.observe(.value, with: {[unowned self] (overviewSnapshot: DataSnapshot) in
							if var overviewValues = overviewSnapshot.value as? Dictionary<String, Any> {
								overviewValues["conversation_key"] = conversationKey
								do {
									if let entity = try self.deserializeEntity(of: ConversationOverview.self, forValues: overviewValues, inContext: context, shouldSave: true),
										let otherProfileID = entity.getOtherProfileIDForDirectMessageConversationKey(authID: profileID) {
										self.getProfile(withProfileID: otherProfileID, forConversationKey: conversationKey, completion: { (error, profile) in
											entity.directProfile = profile
											try? context.save()
										}, withContext: context)
										toRemove.remove(entity)
									}
								} catch let e {
									print(e)
									completion(e)
								}
							}
						})
					} else {
						continue
					}
				}

				self.remove(entities: toRemove, fromContext: context, completion: completion)
			} else {
				self.remove(entities: toRemove, fromContext: context, completion: completion)
			}
		}
	}
	
	func getProfile(withProfileID profileID: String, forConversationKey conversationKey: String, completion: @escaping (Error?, Profile?) -> Void, withContext context: NSManagedObjectContext?) {
		let contextToUse = context ?? {
			let temp = newBackgroundContext()
			temp.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
			return temp
		}()
		
		let reference = Database.database().reference().child("v2/profile").child(profileID)
		conversationProfileReferences[conversationKey] = reference
		
		if let existingHandle = conversationProfileHandles[conversationKey] {
			reference.removeObserver(withHandle: existingHandle)
		}
		
		conversationProfileHandles[conversationKey] =
			reference.observe(.value) { (profileSnapshot) in
				if profileSnapshot.exists(), let profileValues = profileSnapshot.value as? Dictionary<String, Any> {
					do {
						if let entity = try self.deserializeEntity(of: Profile.self, forValues: profileValues, inContext:contextToUse, shouldSave: true) {
							completion(nil, entity)
						} else {
							completion(nil, nil)
						}
					} catch let e {
						completion(e, nil)
					}
				}
		}
	}
	
	func getConversationMessage(forConversationKey conversationKey: String, andMessageKey messageKey: String, completion: @escaping (ConversationMessage?) -> Void) {
		// todo: lookup message first
		
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
		let messageReference = Database.database().reference().child("v2/conversation").child(conversationKey).child("messages").child(messageKey)
		messageReferences[messageKey] = messageReference
		
		if let existingHandle = messageHandles[messageKey] {
			messageReference.removeObserver(withHandle: existingHandle)
		}
		
		messageHandles[messageKey] = messageReference.observe(.value, with: { (messageSnap) in
			if var values = messageSnap.value as? Dictionary<String, Any> {
				values["message_key"] = messageKey
				
				do {
					let message = try self.deserializeEntity(of: ConversationMessage.self, forValues: values, inContext: context, shouldSave: true)
					completion(message)
				} catch let e {
					print(e)
					completion(nil)
				}
			} else {
				completion(nil)
			}
		})
	}
	
	func getExperience(forProfileID profileID: String, andExperienceKey experienceKey: String, completion: @escaping (ConversationMessage?) -> Void) {
		// todo: lookup message first
		
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
		let experienceReference	= Database.database().reference().child("v2/experience").child(profileID).child(experienceKey)
		experienceReferences[experienceKey] = experienceReference
		
		if let existingHandle = experienceHandles[experienceKey] {
			experienceReference.removeObserver(withHandle: existingHandle)
		}
		
		experienceHandles[experienceKey] = experienceReference.observe(.value, with: { (messageSnap) in
			if var values = messageSnap.value as? Dictionary<String, Any> {
				values["message_key"] = experienceKey
				
				do {
					let message = try self.deserializeEntity(of: ConversationMessage.self, forValues: values, inContext: context, shouldSave: true)
					completion(message)
				} catch let e {
					print(e)
					completion(nil)
				}
			} else {
				completion(nil)
			}
		})
	}
	
	func getConversation(withKey conversationKey: String, archivedMessageKeys: [String]?, completion: @escaping (Error?) -> Void) {
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
		let conversationReference = Database.database().reference().child("v2/conversation").child(conversationKey)
		conversationReferences[conversationKey] = conversationReference
		
		if let existingHandle = conversationHandles[conversationKey] {
			conversationReference.removeObserver(withHandle: existingHandle)
		}
		
		conversationHandles[conversationKey] = conversationReference.observe(.value) { (conversationSnapshot: DataSnapshot) in
			if var values = conversationSnapshot.value as? Dictionary<String, Any> {
				values["conversation_key"] = conversationKey
				if let archivedKeys = archivedMessageKeys, let messages = values["messages"] as? Dictionary<String, Any> {
					values["messages"] = messages.filter({ (key, value) -> Bool in
						return !archivedKeys.contains(key)
					})
				}
				
				do {
					let _ = try self.deserializeEntity(of: Conversation.self, forValues: values, inContext: context, shouldSave: true)
					completion(nil)
				} catch let e {
					print(e)
					completion(e)
				}
			} else {
				completion(nil)
			}
		}
	}
	
	func getConversationMessages(withConversationAndMessageKeys conversationAndMessageKeys: [(conversationKey: String, messageKey: String)], completion: @escaping (Error?) -> Void) {
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
		conversationAndMessageKeys.forEach { (conversationKey: String, messageKey: String) in
			let messageReference = Database.database().reference().child("v2/conversation/").child(conversationKey).child("messages/\(messageKey)")
			conversationMessageReferences[messageKey] = messageReference
			
			if let existingHandle = conversationMessageHandles[messageKey] {
				messageReference.removeObserver(withHandle: existingHandle)
			}
			
			conversationMessageHandles[messageKey] = messageReference.observe(.value) { (messageSnapshot: DataSnapshot) in
				if var values = messageSnapshot.value as? Dictionary<String, Any> {
					values["message_key"] = messageKey
					do {
						let _ = try self.deserializeEntity(of: ConversationMessage.self, forValues: values, inContext: context, shouldSave: true)
						completion(nil)
					} catch let e {
						print(e)
						completion(e)
					}
				}
			}
		}
		completion(nil)
	}
	
	func getConversationOverviews(withConversationKeys conversationKeys: [String], completion: @escaping (Error?) -> Void) {
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
		conversationKeys.forEach { conversationKey in
			let overviewReference = Database.database().reference().child("v2/conversation").child(conversationKey).child("overview")
			conversationOverviewReferences[conversationKey] = overviewReference
			
			if let existingHandle = conversationOverviewHandles[conversationKey] {
				overviewReference.removeObserver(withHandle: existingHandle)
			}
			
			conversationOverviewHandles[conversationKey] = overviewReference.observe(.value) { (overviewSnapshot: DataSnapshot) in
				if var values = overviewSnapshot.value as? Dictionary<String, Any> {
					values["conversation_key"] = conversationKey
					do {
						let _ = try self.deserializeEntity(of: ConversationOverview.self, forValues: values, inContext: context, shouldSave: true)
						completion(nil)
					} catch let e {
						print(e)
						completion(e)
					}
				}
			}
		}
		completion(nil)
	}
	
	func getProfiles(withProfileIDs profileIDs: [String], completion: @escaping (Error?) -> Void) {
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

		for profileID in profileIDs {
			let reference = Database.database().reference().child("v2/profile").child(profileID)
			
			if let existingHandle = self.friendProfileHandles[profileID] {
				reference.removeObserver(withHandle: existingHandle)
			}
			
			self.friendProfileHandles[profileID] = reference.observe(.value) { (profileSnapshot) in
				if profileSnapshot.exists(), let profileValues = profileSnapshot.value as? Dictionary<String, Any> {
					do {
						let _ = try self.deserializeEntity(of: Profile.self, forValues: profileValues, inContext: context, shouldSave: true)
					} catch let e {
						completion(e)
					}
				}
			}
		}
		
		completion(nil)
	}
	
	func getFriendProfiles(forUserID userID: String, withCompletion completion: @escaping ([String], Error?) -> Void) {
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
		Database.database().reference().child("v2/profile").child(userID).child("friends").observeSingleEvent(of: .value) { (friendsSnapshot) in
			if friendsSnapshot.exists()  {
				let profileIDs = (friendsSnapshot.children.allObjects as! [DataSnapshot]).map { $0.key }
				self.getProfiles(withProfileIDs: profileIDs, completion: { (error) in
					completion(profileIDs, error)
				})
			} else {
				completion([], nil)
			}
		}
	}
	
	func getLivefeed(forUserID userID: String, maxNotifications: Int, isForProfilePage: Bool, completion: @escaping (NSManagedObjectID?, Error?) -> Void) {
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
		let reference = livefeedReferences[userID] ?? Database.database().reference().child("v2/livefeed").child(userID)
		let query = (isForProfilePage ? reference.queryOrdered(byChild: "profile_id").queryEqual(toValue: userID) : reference.queryOrderedByKey()).queryLimited(toLast: UInt(maxNotifications))
		
		query.observeSingleEvent(of: .value, with: { (livefeedSnap) in
			if livefeedSnap.exists(), var livefeedValues = livefeedSnap.value as? Dictionary<String, Any> {
				livefeedValues["user_id"] = isForProfilePage ? "\(userID)_profile_view" : userID
				do {
					let entity = try self.deserializeEntity(of: Livefeed.self, forValues: livefeedValues, inContext: context, shouldSave: true)
					completion(entity?.objectID, nil)
				} catch let e {
					completion(nil, e)
				}
			} else {
				completion(nil, nil)
			}
		})
	}
	
	func deleteConversationOverview(_ overview: ConversationOverview) {
		let context = overview.managedObjectContext!
		context.delete(overview)
		try? context.save()
	}

	func deleteLivefeedNotification(_ notification: LivefeedNotification) {
		let context = notification.managedObjectContext!
		context.delete(notification)
		try? context.save()
	}
	
	func deleteLivefeedNotificationForCommunitMessage(withEventID eventID: String, andMessageKey messageKey: String) {
		let livefeedNotificationFetchRequest: NSFetchRequest<LivefeedNotification> = LivefeedNotification.fetchRequest()
		livefeedNotificationFetchRequest.predicate = NSPredicate(format: "eventID == %@ AND messageKey == %@", eventID, messageKey)
		
		let replyNotificationFetchRequest: NSFetchRequest<LivefeedNotification> = LivefeedNotification.fetchRequest()
		replyNotificationFetchRequest.predicate = NSPredicate(format: "eventID == %@ AND replyThreadKey == %@", eventID, "r_\(messageKey)")
		
		if let notification = (try? persistentContainer.viewContext.fetch(livefeedNotificationFetchRequest))?.first {
			notification.markedForDeletion = true
		}
		
		if let replyNotifications = (try? persistentContainer.viewContext.fetch(replyNotificationFetchRequest)) {
			replyNotifications.forEach { $0.markedForDeletion = true }
		}
		
		try? persistentContainer.viewContext.save()
	}
	
	func deleteLivefeedNotificationForExperience(withExperienceKey experienceKey: String) {
		let livefeedNotificationFetchRequest: NSFetchRequest<LivefeedNotification> = LivefeedNotification.fetchRequest()
		livefeedNotificationFetchRequest.predicate = NSPredicate(format: "messageKey == %@", experienceKey)
		
		let replyNotificationFetchRequest: NSFetchRequest<LivefeedNotification> = LivefeedNotification.fetchRequest()
		replyNotificationFetchRequest.predicate = NSPredicate(format: "replyThreadKey == %@", "r_\(experienceKey)")
		
		if let notification = (try? persistentContainer.viewContext.fetch(livefeedNotificationFetchRequest))?.first {
			notification.markedForDeletion = true
		}
		
		if let replyNotifications = (try? persistentContainer.viewContext.fetch(replyNotificationFetchRequest)) {
			replyNotifications.forEach { $0.markedForDeletion = true }
		}
		
		try? persistentContainer.viewContext.save()
	}
	
	func deleteLivefeedNotificationForReply(withReplyThreadKey replyThreadKey: String, andMessageKey messageKey: String) {
		let replyNotificationFetchRequest: NSFetchRequest<LivefeedNotification> = LivefeedNotification.fetchRequest()
		replyNotificationFetchRequest.predicate = NSPredicate(format: "replyThreadKey == %@ AND messageKey == %@", replyThreadKey, messageKey)
		
		if let notification = (try? persistentContainer.viewContext.fetch(replyNotificationFetchRequest))?.first {
			notification.markedForDeletion = true
		}
				
		try? persistentContainer.viewContext.save()
	}
	
	func fetch(conversationWithKey conversationKey: String) -> Conversation? {
		let conversationFetchRequest: NSFetchRequest<Conversation> = Conversation.fetchRequest()
		conversationFetchRequest.returnsObjectsAsFaults = false
		conversationFetchRequest.predicate = NSPredicate(format: "key == %@", conversationKey)
		return (try? persistentContainer.viewContext.fetch(conversationFetchRequest))?.first
	}
	
	func getKeyForFirstMessageOfConversation(withKey conversationKey: String) -> String? {
		let sortedMessages = fetch(conversationWithKey: conversationKey)?.messages?.sortedArray(using: [NSSortDescriptor(key: "sent", ascending: true)]) as? [ConversationMessage]
		let message = sortedMessages?.first
		return message?.key
	}
	
	func fetchedResultsControllerForDirectConversationOverviews(forProfileID profileID: String, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<ConversationOverview>? {
		let fetchRequest: NSFetchRequest<ConversationOverview> = ConversationOverview.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "conversationKey BEGINSWITH %@", "d_")
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lastActivity", ascending: false)]
		fetchRequest.returnsObjectsAsFaults = false
		return fetchedResultsController(for: fetchRequest, sectionNameKeyPath: nil, delegate: delegate, errorMessage: "Could not create fetched results controller for conversation overviews")
	}
	
	func fetchedResultsController(forMessagesWithConversationKey conversationKey: String, delegate: NSFetchedResultsControllerDelegate, ascending: Bool) -> NSFetchedResultsController<ConversationMessage>? {
		guard let conversationID = fetch(conversationWithKey: conversationKey)?.objectID else {
			return nil
		}
		let fetchRequest: NSFetchRequest<ConversationMessage> = ConversationMessage.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "conversation == %@", conversationID)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sent", ascending: ascending)]
		return fetchedResultsController(for: fetchRequest, sectionNameKeyPath: nil, delegate: delegate, errorMessage: "Could not create fetched results controller for conversation messages")
	}
	
	func fetchedResultsController(forMessagesWithKeys messageKeys: [String], delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<ConversationMessage>? {
		let fetchRequest: NSFetchRequest<ConversationMessage> = ConversationMessage.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "%@ CONTAINS key", messageKeys)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sent", ascending: false)]
		return fetchedResultsController(for: fetchRequest, sectionNameKeyPath: nil, delegate: delegate, errorMessage: "Could not create fetched results controller for conversation messages")
	}
	
	func fetchedResultsControllerForConversationOverviews(withConversationKeys conversationKeys: [String], delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<ConversationOverview>? {
		let fetchRequest: NSFetchRequest<ConversationOverview> = ConversationOverview.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "%@ CONTAINS conversationKey", conversationKeys)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "conversationKey", ascending: true)]
		return fetchedResultsController(for: fetchRequest, sectionNameKeyPath: nil, delegate: delegate, errorMessage: "Could not create fetched results controller for conversation overviews")
	}
	
	func fetchedResultsControllerForProfiles(withIDs profileIDs: [String], delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<Profile>? {
		let fetchRequest: NSFetchRequest<Profile> = Profile.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "%@ CONTAINS uid", profileIDs)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "username", ascending: true)]
		return fetchedResultsController(for: fetchRequest, sectionNameKeyPath: nil, delegate: delegate, errorMessage: "Could not create fetched results controller for profiles")
	}
	
	func fetchedResultsController(forLivefeedWithObjectID managedObjectID: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<LivefeedNotification>? {
		let fetchRequest: NSFetchRequest<LivefeedNotification> = LivefeedNotification.fetchRequest()
		fetchRequest.predicate = NSPredicate(format: "ANY livefeeds == %@ AND markedForDeletion != YES", managedObjectID)
		fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
		return fetchedResultsController(for: fetchRequest, sectionNameKeyPath: nil, delegate: delegate, errorMessage: "Could not create fetched results controller for livefeed")
	}
	
	private func deserializeEntity<T>(of type: T.Type, forValues values: Dictionary<String, Any>, inContext context: NSManagedObjectContext, shouldSave: Bool) throws -> T? where T: NSManagedObject, T: ManagedObjectDecodable {
		var error: Error? = nil
		var entity: T? = nil
		context.performAndWait { [unowned self] in
			do {
				entity = try self.managedObject(of: T.self, forValues: values, in: context)
			} catch let thrownError {
				print("Error parsing entity \(T.entity().name!): \(thrownError)")
				error = thrownError
			}
			
			if shouldSave {
				do {
					try context.save()
				} catch let thrownError {
					error = thrownError
				}
			}
		}
		
		guard error == nil else {
			throw error!
		}
		
		return entity
	}

	// MARK: ProvidesFirebaseDateFormatter
	
	func getFirebaseDate(fromString string: String) -> NSDate {
		return firebaseDateFormatter.date(from: string)! as NSDate
	}
	
    // MARK: Initialization
    
	public init(persistentContainer: NSPersistentContainer, firebaseDateFormatter: DateFormatter) {
		self.firebaseDateFormatter = firebaseDateFormatter
		
		super.init(persistentContainer: persistentContainer)
		
	}
		
    // MARK: Properties (Injected)
    
    private let disposeBag = DisposeBag()
	private let firebaseDateFormatter: DateFormatter

	// MARK: Properties (Private)
	
	private var profileConversationOverviewsHandle: DatabaseHandle?
	private var profileConversationOverviewsReference: DatabaseReference?
	
	private var conversationHandles = Dictionary<String, DatabaseHandle>()
	private var conversationReferences = Dictionary<String, DatabaseReference>()
	
	private var conversationOverviewHandles = Dictionary<String, DatabaseHandle>()
	private var conversationOverviewReferences = Dictionary<String, DatabaseReference>()
	
	private var conversationMessageHandles = Dictionary<String, DatabaseHandle>()
	private var conversationMessageReferences = Dictionary<String, DatabaseReference>()
	
	private var conversationProfileHandles = Dictionary<String, DatabaseHandle>()
	private var conversationProfileReferences = Dictionary<String, DatabaseReference>()

	private var friendProfileHandles = Dictionary<String, DatabaseHandle>()
	private var friendProfileReferences = Dictionary<String, DatabaseReference>()
	
	private var livefeedHandles = Dictionary<String, DatabaseHandle>()
	private var livefeedReferences = Dictionary<String, DatabaseReference>()
	
	private var messageHandles = Dictionary<String, DatabaseHandle>()
	private var messageReferences = Dictionary<String, DatabaseReference>()
	
	private var experienceHandles = Dictionary<String, DatabaseHandle>()
	private var experienceReferences = Dictionary<String, DatabaseReference>()

}
