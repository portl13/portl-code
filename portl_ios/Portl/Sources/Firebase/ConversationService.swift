//
//  ConversationService.swift
//  Portl
//
//  Created by Jeff Creed on 3/21/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import RxSwift
import FirebaseStorage

class ConversationService {
	func createConversationForShare(shareData: [String: String], message: String) {
		guard let authID = Auth.auth().currentUser?.uid, let eventID = shareData.values.first, let actionDateString = shareData.keys.first else {
			return
		}
		let conversationID = ConversationService.getShareConversationID(fromEventID: eventID, userID: authID, andActionDateString: actionDateString)
		let conversationMessage = FirebaseConversation.Message(profileID: authID, sent: actionDateString, message: message, isHTML: false, imageURL: nil, imageHeight: nil, imageWidth: nil, eventID: nil, eventTitle: nil, videoURL: nil, videoDuration: nil, voteTotal: nil)
		
		if let key = databaseReference.child(conversationID).child(FirebaseKeys.ConversationKeys.messagesKey).childByAutoId().key {
			databaseReference.child(conversationID).child(FirebaseKeys.ConversationKeys.messagesKey)
				.child(key)
				.setValue(conversationMessage.toFirebaseData())
		}
	}
	
	func editMessage(conversationKey: String, message: String, messageKey: String, imageURLString: String?) {
		databaseReference.child(conversationKey)
			.child(FirebaseKeys.ConversationKeys.messagesKey)
			.child(messageKey)
			.child("message")
			.setValue(message)
		
		if let urlString = imageURLString {
			databaseReference.child(conversationKey)
				.child(FirebaseKeys.ConversationKeys.messagesKey)
				.child(messageKey)
				.child("image_url")
				.setValue(urlString)
		}
	}
	
	func editExperience(profileID: String, experienceKey: String, message: String, imageURLString: String?) {
		experienceDatabaseReference.child(profileID)
			.child(experienceKey)
			.child("message")
			.setValue(message)
		
		if let urlString = imageURLString {
			experienceDatabaseReference.child(profileID)
				.child(experienceKey)
				.child("image_url")
				.setValue(urlString)
		}
	}
	
	func deleteMessages(conversationKey: String, messageKeys: Set<String>) {
		guard messageKeys.count > 0 else {
			return
		}
		
		messageKeys.forEach {
			databaseReference.child(conversationKey)
				.child(FirebaseKeys.ConversationKeys.messagesKey)
				.child($0)
				.removeValue()
		}
	}
	
	func deleteMessage(conversationKey: String, messageKey: String, completion: @escaping () -> Void) {
		databaseReference.child(conversationKey)
			.child(FirebaseKeys.ConversationKeys.messagesKey)
			.child(messageKey)
			.removeValue()
		completion()
	}
	
	func deleteExperience(profileID: String, experienceKey: String, completion: @escaping () -> Void) {
		experienceDatabaseReference.child(profileID)
			.child(experienceKey)
			.removeValue()
		
		completion()
	}
	
	func createDirectConversation(withUserWithProfileID profileID: String,  message: String?, imageURL: String?, videoURL: String?, videoDuration: Double?) {
		guard let authID = Auth.auth().currentUser?.uid else {
			return
		}

		let conversationID = ConversationService.getDirectConversationID(fromUserID: authID, andOtherUserID: profileID)
		let conversationMessage = FirebaseConversation.Message(profileID: authID, sent: notificationFormatter.string(from: Date()), message: message, isHTML: false, imageURL: imageURL, imageHeight: nil, imageWidth: nil, eventID: nil, eventTitle: nil, videoURL: videoURL, videoDuration: videoDuration, voteTotal: nil)
		if let key = databaseReference.child(conversationID).child(FirebaseKeys.ConversationKeys.messagesKey).childByAutoId().key {
			databaseReference.child(conversationID).child(FirebaseKeys.ConversationKeys.messagesKey)
				.child(key)
				.setValue(conversationMessage.toFirebaseData())
		}
	}
	
	func share(eventID: String, eventTitle: String, withMessage message: String?, withProfileIDs profileIDs: Set<String>) {
		guard let authID = Auth.auth().currentUser?.uid else {
			return
		}
		
		profileIDs.forEach { (profileID) in
			let conversationID = ConversationService.getDirectConversationID(fromUserID: authID, andOtherUserID: profileID)
			let conversationMessage = FirebaseConversation.Message(profileID: authID, sent: notificationFormatter.string(from: Date()), message: message, isHTML: false, imageURL: nil, imageHeight: nil, imageWidth: nil, eventID: eventID, eventTitle: eventTitle, videoURL: nil, videoDuration: nil, voteTotal: nil)
			if let key = databaseReference.child(conversationID).child(FirebaseKeys.ConversationKeys.messagesKey).childByAutoId().key {
				databaseReference.child(conversationID).child(FirebaseKeys.ConversationKeys.messagesKey)
					.child(key)
					.setValue(conversationMessage.toFirebaseData())
			}
		}
	}
	
	func uploadImageForCurrentConversationMessage(_ imageToUpload: UIImage, completion: @escaping (String?, CGSize?) -> Void) {
		if let conversationID = conversationID {
			let filePath = "conversation/\(conversationID)/\(UUID().uuidString.lowercased()).jpg"
			
			uploadImage(imageToUpload, filePath: filePath, completion: completion)
		}
	}
		
	func uploadImageForExperience(_ imageToUpload: UIImage, profileID: String, completion: @escaping (String?, CGSize?) -> Void) {
		let filePath = "experience/\(profileID)/\(UUID().uuidString.lowercased()).jpg"
		
		uploadImage(imageToUpload, filePath: filePath, completion: completion)
	}
	
	func uploadImage(_ imageToUpload: UIImage, filePath: String, completion: @escaping (String?, CGSize?) -> Void) {
		let imageData = imageToUpload.jpegData(compressionQuality: 0.8)!
		
		uploadData(imageData, contentType: "image/jpg", filePath: filePath) { (url) in
			completion(url, imageToUpload.size)
		}
	}
	
	func uploadVideoForCurrentConversationMessage(_ videoURLOnDevice: URL, completion: @escaping (String?, String?) -> Void) {
		guard let conversationID = conversationID else {
			completion(nil, nil)
			return
		}
		
		let filePath = "conversation/\(conversationID)/\(videoURLOnDevice.lastPathComponent)"
		let thumbPath = "conversation/\(conversationID)/\(videoURLOnDevice.deletingPathExtension().lastPathComponent).jpg"
		
		uploadVideo(videoURLOnDevice, filePath: filePath, thumbnailPath: thumbPath, completion: completion)
	}
	
	func uploadVideoForExperience(_ videoURLOnDevice: URL, profileID: String, completion: @escaping (String?, String?) -> Void) {
		let filePath = "experience/\(profileID)/\(videoURLOnDevice.lastPathComponent)"
		let thumbPath = "experience/\(profileID)/\(videoURLOnDevice.deletingPathExtension().lastPathComponent).jpg"
				
		uploadVideo(videoURLOnDevice, filePath: filePath, thumbnailPath: thumbPath, completion: completion)
	}
	
	func  uploadVideo(_ videoURLOnDevice: URL, filePath: String, thumbnailPath: String, completion: @escaping (String?, String?) -> Void) {

		let thumbnail = VideoUtils.createThumbnailOfVideoFromUrl(url: videoURLOnDevice)!
		
		do {
			let videoData = try Data(contentsOf: videoURLOnDevice)
			uploadImage(thumbnail, filePath: thumbnailPath) {[weak self] (imageURLString, imageSize) in
				guard let imageURLString = imageURLString else {
					completion(nil, nil)
					return
				}
				
				self?.uploadData(videoData, contentType: "video/mp4", filePath: filePath) { (url) in
					completion(url, imageURLString)
				}
			}
		} catch let e {
			print("Error uploading video: \(e.localizedDescription)")
			completion(nil, nil)
		}
	}
	
	func uploadData(_ dataToUpload: Data, contentType: String, filePath: String, completion: @escaping (String?) -> Void) {
		let metaData = StorageMetadata()
		metaData.contentType = contentType
		
		Storage.storage().reference().child(filePath).putData(dataToUpload, metadata: metaData) { (metadata, error) in
			guard error == nil else {
				completion(nil)
				print("Error uploading data: \(error!)")
				return
			}
			
			Storage.storage().reference().child(filePath).downloadURL(completion: { (url, error) in
				guard error == nil, let URL = url else {
					completion(nil)
					return
				}
				completion(URL.absoluteString)
			})
		}
	}
	
	
	func postMessageToCurrentConversation(message: FirebaseConversation.Message) {
		if let key = conversationReference?.child(FirebaseKeys.ConversationKeys.messagesKey).childByAutoId().key {
				conversationReference?.child(FirebaseKeys.ConversationKeys.messagesKey)
					.child(key)
					.setValue(message.toFirebaseData())
		}
	}
	
	func postMessageToConversation(withConversationKey conversationKey: String, message: FirebaseConversation.Message) {
		let reference = databaseReference.child(conversationKey).child(FirebaseKeys.ConversationKeys.messagesKey)
		if let key = reference.childByAutoId().key {
			reference.child(key)
				.setValue(message.toFirebaseData())
		}
	}
	
	func postExperience(experience: FirebaseConversation.Message) {
		let reference = experienceDatabaseReference.child(experience.profileID)
		if let key = reference.childByAutoId().key {
			reference.child(key)
				.setValue(experience.toFirebaseData())
		}
	}
	
	func createOverviewObservables(forIDs conversationIDs: [String]) {
		conversationIDs.forEach { (ID) in
			conversationOverviews[ID] = BehaviorSubject<FirebaseConversation.Overview?>(value: nil)
		}
	}
	
	func loadConversationOverviews(forIDs conversationIDs: [String]) {
		// note: must create observables first
		conversationIDs.forEach { (ID) in
			let reference = databaseReference.child(ID).child(FirebaseKeys.ConversationKeys.overviewKey)
			overviewReferences[ID] = reference
			overviewHandles[ID] = reference.observe(.value, with: {[unowned self] (overviewSnapshot) in
				self.conversationOverviews[ID]?.onNext(ConversationService.conversationOverviewFromDataSnapshot(overviewSnapshot))
			})
		}
	}
	
	func getConversationOverView(forID ID: String, completion: @escaping (FirebaseConversation.Overview?) -> Void) {
		databaseReference.child(ID).child(FirebaseKeys.ConversationKeys.overviewKey).observeSingleEvent(of: .value) {(overviewSnapshot) in
			completion(ConversationService.conversationOverviewFromDataSnapshot(overviewSnapshot))
		}
	}

	func clearConversationOverviews() {
		conversationOverviews.keys.forEach { (ID) in
			removeOverviewHandle(forID: ID)
		}
		conversationOverviews.values.forEach { (overview) in
			overview.onNext(nil)
		}
		conversationOverviews = [:]
	}
	
	func loadConversationForID(forID conversationID: String) {
		self.conversationID = conversationID
		conversationReference = databaseReference.child(conversationID)
		conversationHandle = conversationReference?.observe(.value, with: {[unowned self] (conversationSnapshot) in
			self.conversation.onNext(ConversationService.conversationFromDataSnapshot(conversationSnapshot))
		})
	}
		
	func clearConversation() {
		conversationID = nil
		removeConversationHandle()
		conversation.onNext(nil)
	}
	
	func getFirstMessageForShareConversation(withConversationID conversationID: String, completion: @escaping (String?) -> Void) {
		conversationReference?.child(conversationID)
			.child(FirebaseKeys.ConversationKeys.overviewKey)
			.child(FirebaseKeys.ConversationKeys.OverviewKeys.firstMessageKey).observeSingleEvent(of: .value, with: { (stringSnap) in
				completion(stringSnap.value as? String)
			})
	}
	
	// MARK: Private
	
	private func removeOverviewHandle(forID ID: String) {
		if let reference = overviewReferences[ID], let handle = overviewHandles[ID] {
			reference.removeObserver(withHandle: handle)
		}
		
		overviewReferences.removeValue(forKey: ID)
		overviewHandles.removeValue(forKey: ID)
	}
	
	private func removeConversationHandle() {
		if let reference = conversationReference, let handle = conversationHandle {
			reference.removeObserver(withHandle: handle)
		}
		conversationReference = nil
		conversationHandle = nil
	}
	
	// MARK: Static
	
	static func getCommunityConversationID(fromEventID eventID: String) -> String {
		return String(format: communityIDFormat, eventID)
	}
	
	static func getDirectConversationID(fromUserID userID: String, andOtherUserID otherUserID: String) -> String {
		let sortedIDs = [userID, otherUserID].sorted()
		return String(format: directIDFormat, sortedIDs[0], sortedIDs[1])
	}
	
	static func getShareConversationID(fromEventID eventID: String, userID: String, andActionDateString actionDateString: String) -> String {
		let dateComponent = actionDateString.components(separatedBy: .whitespaces).joined().components(separatedBy: .punctuationCharacters).joined()
		return String(format: shareIDFormat, eventID, userID, dateComponent)
	}
	
	static func getRepliesConversationID(fromMessageKey messageKey: String) -> String {
		return String(format: repliesIDFormat, messageKey)
	}
	
	static func getOriginalMessageKey(fromRepliesKey repliesKey: String) -> String {
		return String(repliesKey.split(separator: "_")[1])
	}
	
	static func getRepliesConversationID(fromProfileID profileID: String, andExperienceKey experienceKey: String) -> String {
		return String(format: experienceRepliesIDFormat, profileID, experienceKey)
	}
	
	static func getProfileIDandExperienceKey(fromRepliesKey repliesKey: String) -> (String, String)? {
		let substrings = repliesKey.split(separator: "_")
		guard substrings.count == 3 else {
			return nil
		}
		return (String(substrings[1]), String(substrings[2]))
	}
	
	static func conversationFromDataSnapshot(_ snapshot: DataSnapshot) -> FirebaseConversation? {
		guard snapshot.exists(), let conversationData = snapshot.value else {
			return nil
		}
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: conversationData, options: [])
			let conversation = try JSONDecoder().decode(FirebaseConversation.self, from: jsonData)
			return conversation
		} catch let error {
			print(error)
			return nil
		}
	}
	
	static func conversationOverviewFromDataSnapshot(_ snapshot: DataSnapshot) -> FirebaseConversation.Overview? {
		guard snapshot.exists(), let overviewData = snapshot.value else {
			return nil
		}
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: overviewData, options: [])
			let overview = try JSONDecoder().decode(FirebaseConversation.Overview.self, from: jsonData)
			return overview
		} catch let error {
			print(error)
			return nil
		}
	}

	static func conversationMessageFromDataSnapshot(_ snapshot: DataSnapshot) -> FirebaseConversation.Message? {
		guard snapshot.exists(), let messageData = snapshot.value else {
			return nil
		}
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: messageData, options: [])
			let message = try JSONDecoder().decode(FirebaseConversation.Message.self, from: jsonData)
			return message
		} catch let error {
			print(error)
			return nil
		}
	}
	
	// MARK: Init
	
	init(databaseRootReference: DatabaseReference, notificationFormatter: DateFormatter) {
		databaseReference = databaseRootReference.child(FirebaseKeys.conversationsKey)
		experienceDatabaseReference = databaseRootReference.child(FirebaseKeys.experiencesKey)
		self.notificationFormatter = notificationFormatter
	}
	
	deinit {
		removeConversationHandle()
	}
	
	// MARK: Properties
	
	var conversationID: String? = nil
	var conversationReference: DatabaseReference? = nil
	var conversationHandle: DatabaseHandle? = nil
	var conversation = BehaviorSubject<FirebaseConversation?>(value: nil)
	
	var overviewReferences = [String : DatabaseReference]()
	var overviewHandles = [String : DatabaseHandle]()
	var conversationOverviews = [String : BehaviorSubject<FirebaseConversation.Overview?>]()
	
	// MARK: Properties (Private)
	
	private let databaseReference: DatabaseReference!
	private let experienceDatabaseReference: DatabaseReference!
	private let notificationFormatter: DateFormatter!
	
	// MARK: Properties (Private Static)

	private static let communityIDFormat = "c_%@"
	private static let directIDFormat = "d_%@_%@"
	private static let shareIDFormat = "s_%@_%@_%@"
	private static let repliesIDFormat = "r_%@"
	private static let experienceRepliesIDFormat = "r_%@_%@"
}
