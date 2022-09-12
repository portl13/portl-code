//
//  Friends.swift
//  Portl
//
//  Created by Jeff Creed on 7/28/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import RxSwift

enum FriendStatus: String {
	case connected = "c"
	case pending = "i"
	case declined = "d"
}

class Friends {
	func sendInvite(toUid uid: String, completion: @escaping (PortlError?) -> Void) {
		guard let authId = Auth.auth().currentUser?.uid else {
			return
		}
		let friendship = [
			FirebaseKeys.FriendsKeys.userOneKey: authId,
			FirebaseKeys.FriendsKeys.userTwoKey: uid,
			FirebaseKeys.FriendsKeys.statusKey: FriendStatus.pending.rawValue,
			FirebaseKeys.FriendsKeys.invitedKey: dateFormatter.string(from: Date())
		]
		if let key = friendsReference.childByAutoId().key {
			let update = ["/v2/friend/\(key)": friendship]
			databaseReference.updateChildValues(update) { (error, ref) in
				guard error == nil else {
					completion(PortlError(error: error, code: 0, message: nil))
					return
				}
				completion(nil)
			}
		}
	}
		
	func removeConnection(toUid uid: String, completion: @escaping (PortlError?) -> Void) {
		guard let authId = Auth.auth().currentUser?.uid else {
			return
		}
		friendsReference.queryOrdered(byChild: FirebaseKeys.FriendsKeys.userOneKey).queryEqual(toValue: authId).observeSingleEvent(of: .value) {[unowned self] (snapshot) in
			if snapshot.exists()  {
				for connection in snapshot.children.allObjects {
					if let connectionInfo = (connection as? DataSnapshot)?.value as? Dictionary<String, Any> {
						if connectionInfo[FirebaseKeys.FriendsKeys.userTwoKey] as! String == uid {
							(connection as! DataSnapshot).ref.removeValue()
							self.friendsSent.removeValue(forKey: uid)
							self.notConnectedSent.removeValue(forKey: uid)
							self.nonDisconnectedFriendships.removeValue(forKey: uid)
							
							completion(nil)
							return
						}
					}
				}
			}
			self.friendsReference.queryOrdered(byChild: FirebaseKeys.FriendsKeys.userTwoKey).queryEqual(toValue: authId).observeSingleEvent(of: .value) { (snapshot) in
				if snapshot.exists()  {
					for connection in snapshot.children.allObjects {
						if let connectionInfo = (connection as? DataSnapshot)?.value as? Dictionary<String, Any> {
							if connectionInfo[FirebaseKeys.FriendsKeys.userOneKey] as! String == uid {
								(connection as! DataSnapshot).ref.removeValue()
								self.friendsReceived.removeValue(forKey: uid)
								self.notConnectedReceived.removeValue(forKey: uid)
								self.nonDisconnectedFriendships.removeValue(forKey: uid)
								completion(nil)
								return
							}
						}
					}
				}
			}
		}
	}
	
	func signOut() {
		friendsReference.queryOrdered(byChild: FirebaseKeys.FriendsKeys.userOneKey).queryEqual(toValue: Auth.auth().currentUser!.uid).removeAllObservers()
		friendsReference.queryOrdered(byChild: FirebaseKeys.FriendsKeys.userTwoKey).queryEqual(toValue: Auth.auth().currentUser!.uid).removeAllObservers()
		friendsSent.removeAll()
		friendsReceived.removeAll()
		notConnectedSent.removeAll()
		notConnectedReceived.removeAll()
		nonDisconnectedFriendships.removeAll()
	}
	
	func getFriendCount(forUserID userID: String, withCompletion completion: @escaping (Int) -> Void) {
		var totalFriends = 0
		friendsReference.queryOrdered(byChild: FirebaseKeys.FriendsKeys.userOneKey).queryEqual(toValue: userID).observeSingleEvent(of: .value) {[unowned self] (snapshot) in
			if snapshot.exists()  {
				for connection in snapshot.children.allObjects {
					if let connectionInfo = (connection as? DataSnapshot)?.value as? Dictionary<String, Any> {
						if connectionInfo[FirebaseKeys.FriendsKeys.statusKey] as! String == FriendStatus.connected.rawValue {
							totalFriends += 1
						}
					}
				}
			}
			self.friendsReference.queryOrdered(byChild: FirebaseKeys.FriendsKeys.userTwoKey).queryEqual(toValue: userID).observeSingleEvent(of: .value) { (snapshot) in
				if snapshot.exists()  {
					for connection in snapshot.children.allObjects {
						if let connectionInfo = (connection as? DataSnapshot)?.value as? Dictionary<String, Any> {
							if connectionInfo[FirebaseKeys.FriendsKeys.statusKey] as! String == FriendStatus.connected.rawValue {
								totalFriends += 1
							}
						}
					}
				}
				completion(totalFriends)
			}
		}
	}
	
	func getFriendProfiles(forUserID userID: String, withCompletion completion: @escaping (Array<Dictionary<String, Any>>, PortlError?) -> Void) {
		var uids = Array<String>()
		var results = Array<Dictionary<String, Any>>()
		
		friendsReference.queryOrdered(byChild: FirebaseKeys.FriendsKeys.userOneKey).queryEqual(toValue: userID).observeSingleEvent(of: .value) {[unowned self] (snapshot) in
			if snapshot.exists()  {
				for connection in snapshot.children.allObjects {
					if let connectionInfo = (connection as? DataSnapshot)?.value as? Dictionary<String, Any> {
						if connectionInfo[FirebaseKeys.FriendsKeys.statusKey] as! String == FriendStatus.connected.rawValue {
							uids.append(connectionInfo[FirebaseKeys.FriendsKeys.userTwoKey] as! String)
						}
					}
				}
			}
			
			self.friendsReference.queryOrdered(byChild: FirebaseKeys.FriendsKeys.userTwoKey).queryEqual(toValue: userID).observeSingleEvent(of: .value) { (snapshot) in
				if snapshot.exists()  {
					for connection in snapshot.children.allObjects {
						if let connectionInfo = (connection as? DataSnapshot)?.value as? Dictionary<String, Any> {
							if connectionInfo[FirebaseKeys.FriendsKeys.statusKey] as! String == FriendStatus.connected.rawValue {
								uids.append(connectionInfo[FirebaseKeys.FriendsKeys.userOneKey] as! String)
							}
						}
					}
				}
	
				if uids.count == 0 {
					completion([], nil)
					return
				}
				
				uids.enumerated().forEach({ (index, uid) in
					self.loadFriendshipProfile(withUid: uid, completion: { (profile) in
						if let profile = profile {
							results.append(profile)
						}
						if index == uids.count - 1 {
							completion(results.sorted(by: { (profile, otherProfile) -> Bool in
								(profile[FirebaseKeys.ProfileKeys.usernameKey] as? String ?? "zzz") < (otherProfile[FirebaseKeys.ProfileKeys.usernameKey] as? String ?? "zzz")
							}), nil)
						}
					})
				})
			}
		}
	}
	
	
	func getUsersForConnectHomeView(withCompletion completion: @escaping ([Dictionary<String, Any>], PortlError?)->Void) {
		// get 20 users
		profileReference.queryLimited(toFirst: 20).observeSingleEvent(of: .value) { (snapshot) in
			if let value = snapshot.value as? Dictionary<String, Dictionary<String, Any>> {
				completion(value.filter({$0.key != Auth.auth().currentUser?.uid}).map({ $0.value }), nil)
			} else {
				completion([], PortlError(error: nil, code: PERRCODE_UNKNOWN_FIREBASE_ERROR, message: PERR_UNKNOWN_FIREBASE_ERROR))
			}
		}
	}
	
	func loadFriendshipProfile(withUid uid: String, completion: @escaping (Dictionary<String, Any>?) -> Void) {
		profileReference.queryOrderedByKey().queryEqual(toValue: uid).observeSingleEvent(of: .value) { (snapshot) in
			completion((snapshot.value as? Dictionary<String, Any>)?[uid] as? Dictionary<String, Any>)
		}
	}
	
	private func clearLocalFriendship(forUID UID: String, wasSent: Bool) {
		self.nonDisconnectedFriendships.removeValue(forKey: UID)

		if (wasSent) {
			self.friendsSent.removeValue(forKey: UID)
			self.notConnectedSent.removeValue(forKey: UID)
		} else {
			self.friendsReceived.removeValue(forKey: UID)
			self.notConnectedReceived.removeValue(forKey: UID)
		}
	}
	
	func loadFriendships() {
		guard let uid = Auth.auth().currentUser?.uid else {
			return
		}
		
		friendsReference.queryOrdered(byChild: FirebaseKeys.FriendsKeys.userOneKey).queryEqual(toValue: uid).observe(.value) {[unowned self] (snapshot) in
			guard let results = snapshot.children.allObjects as? [DataSnapshot] else {
				self.friendsSent.removeAll()
				return
			}
			
			var localFriendsAndNotAcceptedSentUidsNotSeen = Set(self.friendsSent.keys).union(Set(self.notConnectedSent.keys))
			
			for snap in results {
				if var friendship = snap.value as? Dictionary<String, Any> {
					guard let otherUid = friendship[FirebaseKeys.FriendsKeys.userTwoKey] as? String, let status = friendship[FirebaseKeys.FriendsKeys.statusKey] as? String else {
						return
					}
					
					localFriendsAndNotAcceptedSentUidsNotSeen.remove(otherUid)
					
					if status != FriendStatus.declined.rawValue {
						self.loadFriendshipProfile(withUid: otherUid, completion: { (profile) in
							if let profile = profile, !self.friendsSent.keys.contains(otherUid) || self.friendsSent[otherUid]?[FirebaseKeys.FriendsKeys.statusKey] as? String != status {
								if status == FriendStatus.connected.rawValue {
									self.friendsSent[otherUid] = profile
									self.notConnectedSent.removeValue(forKey: otherUid)
								} else if status == FriendStatus.pending.rawValue {
									self.notConnectedSent[otherUid] = friendship
								}
								friendship["profile"] = profile
								self.nonDisconnectedFriendships[otherUid] = friendship
							}
						})
					} else {
						self.clearLocalFriendship(forUID: otherUid, wasSent: true)
					}
				}
			}
			
			localFriendsAndNotAcceptedSentUidsNotSeen.forEach({ (uid) in
				self.clearLocalFriendship(forUID: uid, wasSent: true)
			})
		}
		
		friendsReference.queryOrdered(byChild: FirebaseKeys.FriendsKeys.userTwoKey).queryEqual(toValue: uid).observe(.value) { (snapshot) in
			guard let results = snapshot.children.allObjects as? [DataSnapshot] else {
				self.friendsReceived.removeAll()
				return
			}
			
			var localFriendsAndNotAcceptedReceivedUidsNotSeen = Set(self.friendsReceived.keys).union(Set(self.notConnectedReceived.keys))
			
			for snap in results {
				if var friendship = snap.value as? Dictionary<String, Any> {
					guard let otherUid = friendship[FirebaseKeys.FriendsKeys.userOneKey] as? String, let status = friendship[FirebaseKeys.FriendsKeys.statusKey] as? String else {
						return
					}
					
					localFriendsAndNotAcceptedReceivedUidsNotSeen.remove(otherUid)
					
					if status != FriendStatus.declined.rawValue {
						self.loadFriendshipProfile(withUid: otherUid, completion: { (profile) in
							if let profile = profile, !self.friendsReceived.keys.contains(otherUid) || self.friendsReceived[otherUid]?[FirebaseKeys.FriendsKeys.statusKey] as? String != status {
								if status == FriendStatus.connected.rawValue {
									self.friendsReceived[otherUid] = profile
									self.notConnectedReceived.removeValue(forKey: otherUid)
								} else if status == FriendStatus.pending.rawValue {
									self.notConnectedReceived[otherUid] = friendship
								}
								friendship["profile"] = profile
								self.nonDisconnectedFriendships[otherUid] = friendship
							}
						})
					} else {
						self.clearLocalFriendship(forUID: otherUid, wasSent: false)
					}
				}
			}
			
			localFriendsAndNotAcceptedReceivedUidsNotSeen.forEach({ (uid) in
				self.clearLocalFriendship(forUID: uid, wasSent: false)
			})
		}
	}
	
	private var friendsSent = Dictionary<String, Dictionary<String, Any>>() {
		didSet {
			friendProfiles.onNext(friendsSent.merging(friendsReceived) { (_, new) in new }.values.sorted { (profile, otherProfile) -> Bool in
				profile[FirebaseKeys.ProfileKeys.usernameDKey] as? String ?? "" < otherProfile[FirebaseKeys.ProfileKeys.usernameDKey] as? String ?? ""
			})
		}
	}
	
	private var friendsReceived = Dictionary<String, Dictionary<String, Any>>() {
		didSet {
			friendProfiles.onNext(friendsSent.merging(friendsReceived) { (_, new) in new }.values.sorted { (profile, otherProfile) -> Bool in
				profile[FirebaseKeys.ProfileKeys.usernameDKey] as? String ?? "" < otherProfile[FirebaseKeys.ProfileKeys.usernameDKey] as? String ?? ""
			})
		}
	}
	
	private var notConnectedSent = Dictionary<String, Any>() {
		didSet {
			sentPendingUids.onNext(Array(notConnectedSent.keys))
		}
	}
	
	private var notConnectedReceived = Dictionary<String, Any>() {
		didSet {
			receivedPendingUids.onNext(Array(notConnectedReceived.keys))
		}
	}
	
	private var nonDisconnectedFriendships = Dictionary<String, Dictionary<String, Any>>() {
		didSet {
			orderedFriendshipsWithProfiles.onNext(nonDisconnectedFriendships.values.sorted(by: {[unowned self] (friendship, otherFriendship) -> Bool in
				let dateString = friendship[FirebaseKeys.FriendsKeys.acceptedKey] as? String ?? friendship[FirebaseKeys.FriendsKeys.invitedKey] as! String
				let otherDateString = otherFriendship[FirebaseKeys.FriendsKeys.acceptedKey] as? String ?? otherFriendship[FirebaseKeys.FriendsKeys.invitedKey] as! String
				return self.dateFormatter.date(from: dateString)! > self.dateFormatter.date(from: otherDateString)!
			}))
		}
	}
	
	init(dateFormatter: DateFormatter) {
		self.dateFormatter = dateFormatter
	}
	
	private var dateFormatter: DateFormatter!
	private let databaseReference = Database.database().reference()
	private let friendsReference = Database.database().reference().child("v2").child(FirebaseKeys.friendsKey)
	private let profileReference = Database.database().reference().child("v2").child(FirebaseKeys.profileKey)
	
	let friendProfiles = BehaviorSubject<Array<Dictionary<String, Any>>>(value: [])
	let sentPendingUids = BehaviorSubject<Array<String>>(value: [])
	let receivedPendingUids = BehaviorSubject<Array<String>>(value: [])
	let orderedFriendshipsWithProfiles = BehaviorSubject<Array<Dictionary<String, Any>>>(value: [])
}
