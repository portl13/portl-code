//
//  FCMTokenManager.swift
//  Portl
//
//  Created by Jeff Creed on 6/19/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import FirebaseInstanceID

class FCMTokenManager {

	func removeFCMTokenFromDatabase(token: String) {
		guard let authID = Auth.auth().currentUser?.uid else {
			return
		}
		databaseReference.child(authID).child(token).removeValue()
	}
	
	func saveFCMTokenToDatabase(token: String) {
		guard let authID = Auth.auth().currentUser?.uid else {
			return
		}
		databaseReference.child(authID).child(token).setValue(true)
	}
	
	func retriveTokenFromInstanceNow() {
		InstanceID.instanceID().instanceID { (result, error) in
			print("FCMTokenManager received token: \(String(describing: result?.token))")
			self.currentFCMToken = result?.token
		}
	}
	
	// MARK: Init
	
	init(databaseRootReference: DatabaseRootReferenceQualifier) {
		databaseReference = databaseRootReference.value.child("device")
		
		NotificationCenter.default.addObserver(forName: .InstanceIDTokenRefresh, object: nil, queue: .main) { _ in
			InstanceID.instanceID().instanceID(handler: { (result, error) in
				print("FCMTokenManager received token: \(String(describing: result?.token))")
				self.currentFCMToken = result?.token
			})
		}
	}
	
	// MARK: Properties
	
	var currentFCMToken: String? {
		didSet {
			if let old = oldValue, let new = currentFCMToken, old != new {
				removeFCMTokenFromDatabase(token: old)
				saveFCMTokenToDatabase(token: new)
			} else if oldValue == nil, let new = currentFCMToken {
				saveFCMTokenToDatabase(token: new)
			} else if let old = oldValue, currentFCMToken == nil {
				removeFCMTokenFromDatabase(token: old)
			}
		}
	}
	
	// MARK: Properties (Private)
	
	private let databaseReference: DatabaseReference!
}
