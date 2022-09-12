//
//  LivefeedService.swift
//  Portl
//
//  Created by Jeff Creed on 3/28/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import RxSwift

class LivefeedService {
	
	func loadIndividualLivefeed(forProfileID profileID: String, completion: @escaping ([String: FirebaseLivefeedObject]?) -> Void) {
		livefeedReference = databaseReference.child(profileID)
		livefeedReference?.queryOrdered(byChild: FirebaseKeys.LivefeedKeys.profileIDKey).queryEqual(toValue: profileID).observe(.value, with: { (livefeedSnapshot) in
			completion(self.livefeedFromDataSnapshot(livefeedSnapshot))
		})
	}
	
	func loadLivefeed(forProfileID profileID: String, completion: @escaping ([String: FirebaseLivefeedObject]?) -> Void) {
		livefeedReference = databaseReference.child(profileID)
		livefeedReference?.observeSingleEvent(of: .value, with: {[unowned self] (livefeedSnapshot) in
			completion(self.livefeedFromDataSnapshot(livefeedSnapshot))
		})
	}
	
	func clearLivefeed() {
		removeLivefeedHandle()
		livefeed.onNext(nil)
	}
	
	func getEventObservable(forEventID eventID: String) -> BehaviorSubject<FirebaseEvent?> {
		guard let found = eventObservables[eventID] else {
			let newObservable = BehaviorSubject<FirebaseEvent?>(value: nil)
			let newReference = eventDatabaseReference.child(eventID)
			let newHandle = newReference.observe(.value) { (eventSnapshot) in
				newObservable.onNext(EventService.eventFromDataSnapshot(eventSnapshot))
			}
			eventObservables[eventID] = newObservable
			eventReferences[eventID] = newReference
			eventHandles[eventID] = newHandle
			return newObservable
		}
		return found
	}
	
	func cleanupEventObservables() {
		// todo:
	}
	
	func getConversationObservable(forConversationID conversationID: String) -> BehaviorSubject<FirebaseConversation.Overview?> {
		guard let found = conversationObservables[conversationID] else {
			let newObservable = BehaviorSubject<FirebaseConversation.Overview?>(value: nil)
			let newReference = conversationDatabaseReference.child(conversationID).child(FirebaseKeys.ConversationKeys.overviewKey)
			let newHandle = newReference.observe(.value) { (overviewSnapshot) in
				newObservable.onNext(ConversationService.conversationOverviewFromDataSnapshot(overviewSnapshot))
			}
			conversationObservables[conversationID] = newObservable
			conversationReferences[conversationID] = newReference
			conversationHandles[conversationID] = newHandle
			return newObservable
		}
		return found
	}

	func cleanupConversationObservables() {
		// todo:
	}
	
	func getExperiencePostObservable(forProfileID profileID: String, andMessageID messageID: String) -> BehaviorSubject<FirebaseConversation.Message?> {
		guard let found = experiencePostObservables[messageID] else {
			let newObservable = BehaviorSubject<FirebaseConversation.Message?>(value: nil)
			let newReference = experienceDatabaseReference.child(profileID).child(messageID)
			let newHandle = newReference.observe(.value) { (messageSnapshot) in
				newObservable.onNext(ConversationService.conversationMessageFromDataSnapshot(messageSnapshot))
			}
			experiencePostObservables[messageID] = newObservable
			experiencePostReferences[messageID] = newReference
			experiencePostHandles[messageID] = newHandle
			return newObservable
		}
		return found
	}
	
	func getConversationMessageObservable(forConversationID conversationID: String, andMessageID messageID: String) -> BehaviorSubject<FirebaseConversation.Message?> {
		guard let found = conversationMessageObservables[messageID] else {
			let newObservable = BehaviorSubject<FirebaseConversation.Message?>(value: nil)
			let newReference = conversationDatabaseReference.child(conversationID).child(FirebaseKeys.ConversationKeys.messagesKey).child(messageID)
			let newHandle = newReference.observe(.value) { (messageSnapshot) in
				newObservable.onNext(ConversationService.conversationMessageFromDataSnapshot(messageSnapshot))
			}
			conversationMessageObservables[messageID] = newObservable
			conversationMessageReferences[messageID] = newReference
			conversationMessageHandles[messageID] = newHandle
			return newObservable
		}
		return found
	}
	
	func cleanupConversationMessageObservables() {
		// todo:
	}
	
	func getConversationOverviewObservable(forConversationID conversationID: String) -> BehaviorSubject<FirebaseConversation.Overview?> {
		guard let found = conversationOverviewObservables[conversationID] else {
			let newObservable = BehaviorSubject<FirebaseConversation.Overview?>(value: nil)
			let newReference = conversationDatabaseReference.child(conversationID).child(FirebaseKeys.ConversationKeys.overviewKey)
			let newHandle = newReference.observe(.value) { (overviewSnapshot) in
				newObservable.onNext(ConversationService.conversationOverviewFromDataSnapshot(overviewSnapshot))
			}
			conversationOverviewObservables[conversationID] = newObservable
			conversationOverviewReferences[conversationID] = newReference
			conversationOverviewHandles[conversationID] = newHandle
			return newObservable
		}
		
		return found
	}
	
	func cleanupConversationOverviewObservables() {
		// todo:
	}
	
	func getProfileObservable(forProfileID profileID: String) -> BehaviorSubject<FirebaseProfile?> {
		guard let found = profileObservables[profileID] else {
			let newObservable = BehaviorSubject<FirebaseProfile?>(value: nil)
			let newReference = profileDatabaseReference.child(profileID)
			let newHandle = newReference.observe(.value) { (profileSnapshot) in
				newObservable.onNext(UserProfileService.userProfileFromDataSnapshot(profileSnapshot))
			}
			profileObservables[profileID] = newObservable
			profileReferences[profileID] = newReference
			profileHandles[profileID] = newHandle
			return newObservable
		}
		return found
	}
	
	func cleanupProfileObservables() {
		// todo:
	}
	
	func getGoingDataObservable(forEventID eventID: String) -> BehaviorSubject<FirebaseProfile.Events.GoingData?> {
		guard let found = goingDataObservables[eventID] else {
			let newObservable = BehaviorSubject<FirebaseProfile.Events.GoingData?>(value: nil)
			guard let authUID = Auth.auth().currentUser?.uid else {
				return newObservable
			}
			
			let newReference = profileDatabaseReference.child(authUID).child(FirebaseKeys.ProfileKeys.eventsKey).child(FirebaseKeys.ProfileKeys.EventKeys.goingKey).child(eventID)
			let newHandle = newReference.observe(.value) { (goingSnapshot) in
				newObservable.onNext(UserProfileService.eventGoingDataFromDataSnapshot(goingSnapshot))
			}
			goingDataObservables[eventID] = newObservable
			goingDataReferences[eventID] = newReference
			goingDataHandles[eventID] = newHandle
			return newObservable
		}
		return found
	}
	
	func cleanupGoingDataObservables() {
		
	}
	
	// MARK: Private
	
	private func removeLivefeedHandle() {
		if let reference = livefeedReference, let handle = livefeedHandle {
			reference.removeObserver(withHandle: handle)
		}
		livefeedReference = nil
		livefeedHandle = nil
	}
	
	private func livefeedFromDataSnapshot(_ snapshot: DataSnapshot) -> [String: FirebaseLivefeedObject]? {
		guard snapshot.exists(), let livefeedObjectData = snapshot.value else {
			return nil
		}
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: livefeedObjectData, options: [])
			let livefeed = try JSONDecoder().decode([String: FirebaseLivefeedObject].self, from: jsonData)
			return livefeed
		} catch let error {
			print(error)
			return nil
		}
	}

	
	// MARK: Init
	
	init(databaseRootReference: DatabaseReference) {
		databaseReference = databaseRootReference.child(FirebaseKeys.livefeedsKey)
		eventDatabaseReference = databaseRootReference.child(FirebaseKeys.eventsKey)
		conversationDatabaseReference = databaseRootReference.child(FirebaseKeys.conversationsKey)
		profileDatabaseReference = databaseRootReference.child(FirebaseKeys.profileKey)
		experienceDatabaseReference = databaseRootReference.child(FirebaseKeys.experiencesKey)
	}
	
	deinit {
		removeLivefeedHandle()
	}
	
	// MARK: Properties
	
	var livefeedReference: DatabaseReference? = nil
	var livefeedHandle: DatabaseHandle? = nil
	var livefeed = BehaviorSubject<[String: FirebaseLivefeedObject]?>(value: nil)
	
	var eventObservables = [String: BehaviorSubject<FirebaseEvent?>]()
	var eventReferences = [String: DatabaseReference]()
	var eventHandles = [String: DatabaseHandle]()
	
	var conversationObservables = [String: BehaviorSubject<FirebaseConversation.Overview?>]()
	var conversationReferences = [String: DatabaseReference]()
	var conversationHandles = [String: DatabaseHandle]()
	
	var conversationMessageObservables = [String: BehaviorSubject<FirebaseConversation.Message?>]()
	var conversationMessageReferences = [String: DatabaseReference]()
	var conversationMessageHandles = [String: DatabaseHandle]()
	
	var experiencePostObservables = [String: BehaviorSubject<FirebaseConversation.Message?>]()
	var experiencePostReferences = [String: DatabaseReference]()
	var experiencePostHandles = [String: DatabaseHandle]()
	
	var conversationOverviewObservables = [String: BehaviorSubject<FirebaseConversation.Overview?>]()
	var conversationOverviewReferences = [String: DatabaseReference]()
	var conversationOverviewHandles = [String: DatabaseHandle]()
	
	var profileObservables = [String: BehaviorSubject<FirebaseProfile?>]()
	var profileReferences = [String: DatabaseReference]()
	var profileHandles = [String: DatabaseHandle]()
	
	var goingDataObservables = [String: BehaviorSubject<FirebaseProfile.Events.GoingData?>]()
	var goingDataReferences = [String: DatabaseReference]()
	var goingDataHandles = [String: DatabaseHandle]()
	
	// MARK: Properties (Private)
	
	private let databaseReference: DatabaseReference!
	private let eventDatabaseReference: DatabaseReference!
	private let conversationDatabaseReference: DatabaseReference!
	private let profileDatabaseReference: DatabaseReference!
	private let experienceDatabaseReference: DatabaseReference!
	
	// todo: paginate (need migration) livefeed needs overview object next to notifications
	
}
