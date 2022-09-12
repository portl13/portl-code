//
//  UserProfileService.swift
//  Portl
//
//  Created by Jeff Creed on 3/15/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import RxSwift

class UserProfileService {
	
	func getProfileBio() -> String? {
		var currentValue: String?
		
		do {
			currentValue = try authenticatedProfile.value()?.bio
		} catch let e {
			print(e.localizedDescription)
		}
		
		return currentValue
	}
	
	func getVoteStatusForConversationMessage(conversationKey: String, messageKey: String) -> Bool? {
		var currentValue: Bool?
		
		do {
			let profile = try privateProfile.value()
			currentValue = profile?.votes?.conversation?[conversationKey]?[messageKey]
		} catch let e {
			print(e.localizedDescription)
		}
		
		return currentValue
	}
		
	func getVoteStatusForExperience(profileID: String, experienceKey: String) -> Bool? {
		var currentValue: Bool?
		
		do {
			let profile = try privateProfile.value()
			currentValue = profile?.votes?.experience?[profileID]?[experienceKey]
		} catch let e {
			print(e.localizedDescription)
		}
		
		return currentValue
	}
		
	func voteOnConversationMessage(withConversationKey converstaionKey: String, andMessageKey messageKey: String, vote: Bool?) {
		let profileVoteRef = getVotesReference()?
			.child(FirebaseKeys.ProfilePrivateKeys.VotesKeys.conversationKey)
			.child(converstaionKey)
			.child(messageKey)
		
		if let vote = vote {
			profileVoteRef?.setValue(vote)
		} else {
			profileVoteRef?.removeValue()
		}
	}
	
	func voteOnExperience(withProfileID profileID: String, andExperienceKey experienceKey: String, vote: Bool?) {
		let profileVoteRef = getVotesReference()?
			.child(FirebaseKeys.ProfilePrivateKeys.VotesKeys.experienceKey)
			.child(profileID)
			.child(experienceKey)
		
		if let vote = vote {
			profileVoteRef?.setValue(NSNumber(booleanLiteral: vote))
		} else {
			profileVoteRef?.removeValue()
		}
	}
	
	func markAccountForDeletion(withCompletion completion: @escaping (Bool) -> Void) {
		guard let authID = Auth.auth().currentUser?.uid else {
			completion(false)
			return
		}
		
		let calendar = Calendar.current
		let deletionDate = calendar.date(byAdding: .day, value: 3, to: Date())!
		let deletionDateString = dateFormatter.string(from: deletionDate)
		
		accountsToDeleteReference?
			.child(authID)
			.setValue(deletionDateString) { (error, ref) in
				guard error == nil else {
					completion(false)
					return
				}
				completion(true)
		}
	}
	
	func archiveConversation(withKey conversationKey: String, completion: ((String?) -> ())?) {
		let update = ["is_archived": true]
		
		authenticatedProfileReference?
			.child(FirebaseKeys.ProfileKeys.conversationKey)
			.child(conversationKey)
			.updateChildValues(update) { (error:Error?, ref:DatabaseReference) in
				completion?(error?.localizedDescription)
			}
	}
	
	func archiveMesssages(inConversationWithKey conversationKey: String, messageKeys: Set<String>, completion: ((String?) -> ())?) {
		guard let profile = try? authenticatedProfile.value() else {
			completion?(nil)
			return
		}
		
		guard !messageKeys.isEmpty else {
			completion?(nil)
			return
		}
		
		var archived = Set(profile.conversation?[conversationKey]?.archivedMessages?.keys.sorted() ?? [String]())
		archived = archived.union(Set(messageKeys))
		
		var updates = [String: Bool]()
		
		archived.forEach { key in
			updates[key] = true
		}
		
		authenticatedProfileReference?
			.child(FirebaseKeys.ProfileKeys.conversationKey)
			.child(conversationKey)
			.child(FirebaseKeys.ProfileKeys.ConversationKeys.archivedMessagesKey)
			.updateChildValues(updates) { (error:Error?, ref:DatabaseReference) in
				completion?(error?.localizedDescription)
			}
	}
	
	func markConversationSeen(conversationKey: String) {
		guard let profile = try? authenticatedProfile.value() else {
			return
		}
		
		if profile.conversation?[conversationKey]?.hasNew == true {
			authenticatedProfileReference?
				.child(FirebaseKeys.ProfileKeys.conversationKey)
				.child(conversationKey)
				.child(FirebaseKeys.ProfileKeys.ConversationKeys.hasNewKey)
				.setValue(false)
		}
	}
	
	func markConversationMessagesSeen(messageKeys: [String]) {
		guard messageKeys.count > 0, let profile = try? authenticatedProfile.value() else {
			return
		}
		
		var updates = [String: Any]()
		messageKeys.forEach { key in
			if profile.unreadMessages?[key] != nil {
				updates[key] = NSNull()
			}
		}

		authenticatedProfileReference?
			.child(FirebaseKeys.ProfileKeys.unreadMessagesKey)
			.updateChildValues(updates)
	}
	
	func markLivefeedNotificationsSeen(notificationKeys: [String]) {
		guard notificationKeys.count > 0, let profile = try? authenticatedProfile.value() else {
			return
		}
		
		var updates = [String: Any]()
		notificationKeys.forEach { key in
			if profile.unseenLivefeed?[key] != nil {
				updates[key] = NSNull()
			}
		}
		
		authenticatedProfileReference?
			.child(FirebaseKeys.ProfileKeys.unseenLivefeedKey)
			.updateChildValues(updates)
	}
	
	func shareEvent(_ eventID: String, completion: ((String) -> Void)? = nil) {
		let actionDateString = dateFormatter.string(from: Date())
		
		authenticatedProfileReference?.child(FirebaseKeys.ProfileKeys.eventsKey)
			.child(FirebaseKeys.ProfileKeys.EventKeys.shareKey)
			.child(actionDateString)
			.setValue(eventID)
		
		completion?(actionDateString)
	}
	
	func deleteShare(_ actionDateString: String, completion: @escaping () -> Void) {		
		authenticatedProfileReference?.child(FirebaseKeys.ProfileKeys.eventsKey)
			.child(FirebaseKeys.ProfileKeys.EventKeys.shareKey)
			.child(actionDateString)
			.removeValue()
		
		completion()
	}
	
	func setGoingData(_ goingData: FirebaseProfile.Events.GoingData?, forEventID eventID: String) {
		let update = goingData?.toFirebaseData()
		
		let ref = authenticatedProfileReference?
			.child(FirebaseKeys.ProfileKeys.eventsKey)
			.child(FirebaseKeys.ProfileKeys.EventKeys.goingKey)
			.child(eventID)
		
		if let update = update {
			ref?.updateChildValues(update)
		} else {
			ref?.removeValue()
		}
	}
	
	func setFavorite(_ favoriteData: FirebaseProfile.Events.EventActionData?, forEventID eventID: String) {
		let update = favoriteData?.toFirebaseData()
		
		let ref = authenticatedProfileReference?
			.child(FirebaseKeys.ProfileKeys.eventsKey)
			.child(FirebaseKeys.ProfileKeys.EventKeys.favoritesKey)
			.child(eventID)
		
		if let update = update {
			ref?.updateChildValues(update)
		} else {
			ref?.removeValue()
		}
	}
	
	func setFollowing(_ following: Bool, forArtistID artistID: String) {
		let ref = authenticatedProfileReference?
			.child(FirebaseKeys.ProfileKeys.followingKey)
			.child(FirebaseKeys.ProfileKeys.FollowingKeys.artistKey)
			.child(artistID)
			
		if following {
			ref?.setValue(true)
		} else {
			ref?.removeValue()
		}
	}
	
	func setFollowing(_ following: Bool, forVenueID venueID: String) {
		let ref = authenticatedProfileReference?
			.child(FirebaseKeys.ProfileKeys.followingKey)
			.child(FirebaseKeys.ProfileKeys.FollowingKeys.venueKey)
			.child(venueID)
			
		if following {
			ref?.setValue(true)
		} else {
			ref?.removeValue()
		}
	}
	
	func getProfileAvatar(profileID: String, completion: @escaping (String?) -> Void) {
		databaseReference.child(profileID).observeSingleEvent(of: .value) { (profileSnapshot) in
			guard let profile = UserProfileService.userProfileFromDataSnapshot(profileSnapshot) else {
				completion(nil)
				return
			}
			completion(profile.avatar)
		}
	}
		
	func getUsername(profileID: String, completion: @escaping (String) -> Void) {
		databaseReference.child(profileID).observeSingleEvent(of: .value) { (profileSnapshot) in
			guard let profile = UserProfileService.userProfileFromDataSnapshot(profileSnapshot) else {
				completion("unknown user")
				return
			}
			completion(profile.username)
		}
	}
	
	func loadOtherUserProfile(profileID: String) {
		otherUserProfileReference = databaseReference.child(profileID)
		otherUserProfileHandle = otherUserProfileReference?.observe(.value, with: {[unowned self] (profileSnapshot) in
			self.otherUserProfile.onNext(UserProfileService.userProfileFromDataSnapshot(profileSnapshot))
		})
	}
	
	func clearOtherUserProfile() {
		removeOtherUserHandle()
		otherUserProfile.onNext(nil)
	}
		
	// MARK: Static
	
	static func userProfileFromDataSnapshot(_ snapshot: DataSnapshot) -> FirebaseProfile? {
		guard snapshot.exists(), let profileData = snapshot.value else {
			return nil
		}
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: profileData, options: [])
			let profile = try JSONDecoder().decode(FirebaseProfile.self, from: jsonData)
			return profile
		} catch let error {
			print(error)
			return nil
		}
	}
	
	static func privateProfileFromDataSnapshot(_ snapshot: DataSnapshot) -> FirebasePrivateProfile? {
		guard snapshot.exists(), let privateProfileData = snapshot.value else {
			return nil
		}
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: privateProfileData, options: [])
			let profile = try JSONDecoder().decode(FirebasePrivateProfile.self, from: jsonData)
			return profile
		} catch let error {
			print(error)
			return nil
		}
	}
	
	static func eventGoingDataFromDataSnapshot(_ snapshot: DataSnapshot) -> FirebaseProfile.Events.GoingData? {
		guard snapshot.exists(), let goingData = snapshot.value else {
			return nil
		}
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: goingData, options: [])
			let goingData = try JSONDecoder().decode(FirebaseProfile.Events.GoingData.self, from: jsonData)
			return goingData
		} catch let error {
			print(error)
			return nil
		}
	}
	
	// MARK: Edit
	
	func updateBirthday(birthday: String, completion: @escaping (PortlError?) -> Void) {
		let updates = [FirebaseKeys.ProfileKeys.birthDateKey: birthday]
		
		saveProfile(updates: updates, completion: completion)
	}
	
	func updateAvatar(urlString: String?, completion: @escaping (PortlError?) -> Void) {
		let updates = [FirebaseKeys.ProfileKeys.avatarKey: urlString ?? ""]
		
		saveProfile(updates: updates, completion: completion)
	}
	
	func updateName(firstName: String?, lastName: String?, completion: @escaping (PortlError?) -> Void) {
		let trimmedFirst = firstName?.trimmingCharacters(in: .whitespacesAndNewlines)
		let trimmedLast = lastName?.trimmingCharacters(in: .whitespacesAndNewlines)
		
		let updates = [FirebaseKeys.ProfileKeys.firstNameKey: trimmedFirst ?? "", FirebaseKeys.ProfileKeys.lastNameKey: trimmedLast ?? "", FirebaseKeys.ProfileKeys.firstLastKey: "\(trimmedFirst?.lowercased() ?? "") \(trimmedLast?.lowercased() ?? "")"]
		saveProfile(updates: updates, completion: completion)
	}

	func updateUsername(username: String, completion: @escaping (PortlError?) -> Void) {
		let trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)
		let updates = [FirebaseKeys.ProfileKeys.usernameKey: trimmed, FirebaseKeys.ProfileKeys.usernameDKey: trimmed.lowercased()]
		
		databaseReference.queryOrdered(byChild: FirebaseKeys.ProfileKeys.usernameDKey).queryEqual(toValue: username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()).observeSingleEvent(of: .value) {[unowned self] (snapshot) in
			if let _ = snapshot.value as? Dictionary<String, Any> {
				completion(PortlError(error: nil, code: PERRCODE_USERNAME_ALREADY_TAKEN, message: PERR_USERNAME_ALREADY_TAKEN))
			} else {
				self.saveProfile(updates: updates, completion: completion)
			}
		}
	}
	
	func updateZipcode(zipcode: String, completion: @escaping (PortlError?) -> Void) {
		let updates = [FirebaseKeys.ProfileKeys.zipcodeKey: zipcode]
		saveProfile(updates: updates, completion: completion)
	}
	
	func updateWebsite(website: String?, completion: @escaping (PortlError?) -> Void) {
		let updates = [FirebaseKeys.ProfileKeys.websiteKey: website ?? ""]
		saveProfile(updates: updates, completion: completion)
	}
	
	func updateBio(bioText: String, completion: @escaping (PortlError?) -> Void) {
		let updates = [FirebaseKeys.ProfileKeys.bioKey: bioText]
		saveProfile(updates: updates, completion: completion)
	}
	
	// MARK: Private
	
	private func getVotesReference() -> DatabaseReference? {
		return privateProfileReference?.child(FirebaseKeys.ProfilePrivateKeys.votesKey)
	}
	
	private func saveProfile(updates: Dictionary<String, Any>, completion: @escaping (PortlError?) -> Void) {
		guard let authUid = Auth.auth().currentUser?.uid else {
			completion(PortlError(error: nil, code: PERRCODE_NOT_AUTHORIZED, message: PERR_NOT_AUTHORIZED))
			return
		}
		
		databaseReference.child(authUid).updateChildValues(updates) { (error, ref) in
			guard error == nil else {
				completion(PortlError(error: error, code: PERRCODE_UNKNOWN_FIREBASE_ERROR, message: PERR_UNKNOWN_FIREBASE_ERROR))
				return
			}
			completion(nil)
		}
	}
	
	private func removeOtherUserHandle() {
		if let reference = self.otherUserProfileReference, let handle = self.otherUserProfileHandle {
			reference.removeObserver(withHandle: handle)
		}
		self.otherUserProfileHandle = nil
		self.otherUserProfileReference = nil
	}
	
	private func removeAuthUserHandle() {
		if let reference = authenticatedProfileReference, let handle = authenticatedProfileHandle {
			reference.removeObserver(withHandle: handle)
		}
		authenticatedProfileHandle = nil
		authenticatedProfileReference = nil
		if let privateReference = privateProfileReference, let privateHandle = privateProfileHandle {
			privateReference.removeObserver(withHandle: privateHandle)
		}
		privateProfileReference = nil
		privateProfileHandle = nil
	}
	
	// MARK: Init
	
	init(databaseRootReference: DatabaseReference, dateFormatter: DateFormatter, firebaseService: FirebaseDataProviding) {
		self.firebaseService = firebaseService
		
		databaseReference = databaseRootReference.child(FirebaseKeys.profileKey)
		privateDatabaseReference = databaseRootReference.child(FirebaseKeys.profilePrivateKey)
		accountsToDeleteReference = databaseRootReference.child("delete")

		self.dateFormatter = dateFormatter
		
		authenticatedProfile = BehaviorSubject<FirebaseProfile?>(value: nil)
		privateProfile = BehaviorSubject<FirebasePrivateProfile?>(value: nil)
		otherUserProfile = BehaviorSubject<FirebaseProfile?>(value: nil)
		
		NotificationCenter.default.addObserver(forName: .authStateChanged, object: nil, queue: nil) {[unowned self] (_) in
			if let user = Auth.auth().currentUser, !user.isAnonymous {
				// first ensure that a user logging in has their account deletion canceled (if set)
				self.accountsToDeleteReference?.child(user.uid).removeValue()
				self.authenticatedProfileReference = self.databaseReference.child(user.uid)
				self.authenticatedProfileHandle = self.authenticatedProfileReference?.observe(.value, with: {[unowned self] (profileSnapshot) in
					let profile = UserProfileService.userProfileFromDataSnapshot(profileSnapshot)
					self.authenticatedProfile.onNext(profile)
					self.liveFeedNotificationCount = profile?.unseenLivefeed?.count ?? 0
					
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: Notification.Name(gNotificationNotificationListUpdated), object: nil, userInfo: ["count": NSNumber(value: profile?.unseenLivefeed?.count ?? 0)])
						NotificationCenter.default.post(name: Notification.Name(gNotificationMessageRoomsUpdated), object: nil, userInfo: ["count": NSNumber(value: profile?.unreadMessages?.count ?? 0)])
					}
				})
				
				self.privateProfileReference = self.privateDatabaseReference.child(user.uid)
				self.privateProfileHandle = self.privateProfileReference?.observe(.value, with: {[unowned self] (privateProfileSnapshot) in
					let privateProfile = UserProfileService.privateProfileFromDataSnapshot(privateProfileSnapshot)
					self.privateProfile.onNext(privateProfile)
				})
			} else {
				self.removeAuthUserHandle()
				self.authenticatedProfile.onNext(nil)
				self.privateProfile.onNext(nil)
				self.firebaseService.clearPersonalData()
				self.liveFeedNotificationCount = 0
			}
		}
	}
	
	deinit {
		removeAuthUserHandle()
	}
	
	// MARK: Properties
	
	var liveFeedNotificationCount = 0
	
	var authenticatedProfileReference: DatabaseReference? = nil
	var authenticatedProfileHandle: DatabaseHandle? = nil
	var authenticatedProfile: BehaviorSubject<FirebaseProfile?>
	
	var privateProfileReference: DatabaseReference? = nil
	var privateProfileHandle: DatabaseHandle? = nil
	var privateProfile: BehaviorSubject<FirebasePrivateProfile?>
	
	var otherUserProfileReference: DatabaseReference? = nil
	var otherUserProfileHandle: DatabaseHandle? = nil
	var otherUserProfile: BehaviorSubject<FirebaseProfile?>
	
	var accountsToDeleteReference: DatabaseReference?
	
	// MARK: Properties (Private)
	
	private let databaseReference: DatabaseReference!
	private let privateDatabaseReference: DatabaseReference!
	private let dateFormatter: DateFormatter!
	private let firebaseService: FirebaseDataProviding!
	
}
