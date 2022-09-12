//
//  ProfileService.swift
//  Portl
//
//  Created by Jeff Creed on 8/2/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import FirebaseFunctions

class OldProfileService {
	func updateBio(bio: String, completion: @escaping (PortlError?) -> Void) {
		let updates = [FirebaseKeys.ProfileKeys.bioKey: bio]
		
		saveProfile(updates: updates, completion: completion)
	}
	
	func updateBirthday(birthday: String, completion: @escaping (PortlError?) -> Void) {
		let updates = [FirebaseKeys.ProfileKeys.birthDateKey: birthday]
		
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
	
	func updateGender(gender: String, completion: @escaping (PortlError?) -> Void) {
		let updates = [FirebaseKeys.ProfileKeys.genderKey: gender]
		saveProfile(updates: updates, completion: completion)
	}
	
	func updateName(firstName: String?, lastName: String?, completion: @escaping (PortlError?) -> Void) {
		let trimmedFirst = firstName?.trimmingCharacters(in: .whitespacesAndNewlines)
		let trimmedLast = lastName?.trimmingCharacters(in: .whitespacesAndNewlines)
		
		let updates = [FirebaseKeys.ProfileKeys.firstNameKey: trimmedFirst ?? "", FirebaseKeys.ProfileKeys.lastNameKey: trimmedLast ?? "", FirebaseKeys.ProfileKeys.firstLastKey: "\(trimmedFirst?.lowercased() ?? "") \(trimmedLast?.lowercased() ?? "")"]
		saveProfile(updates: updates, completion: completion)
	}
	
	func updateOptionalInformationFromSignUp(zipcode: String?, firstName: String?, lastName: String?, birthDate: String?, gender: String?, completion: @escaping (PortlError?)->Void) {
		guard let authUser = Auth.auth().currentUser else {
			completion(PortlError(error: nil, code: PERRCODE_NOT_AUTHORIZED, message: PERR_NOT_AUTHORIZED))
			return
		}
		
		var firstLast = ""
		if let first = firstName {
			firstLast += "\(first.lowercased())"
		}
		if let last = lastName {
			if firstLast.count == 0 {
				firstLast += " "
			}
			firstLast += "\(last.lowercased())"
		}
		
		let updates = [
			FirebaseKeys.ProfileKeys.zipcodeKey: zipcode,
			FirebaseKeys.ProfileKeys.firstNameKey: firstName,
			FirebaseKeys.ProfileKeys.lastNameKey: lastName,
			FirebaseKeys.ProfileKeys.firstLastKey: firstLast.count > 0 ? firstLast : nil,
			FirebaseKeys.ProfileKeys.birthDateKey: birthDate,
			FirebaseKeys.ProfileKeys.genderKey: gender?.count ?? 0 > 0 ? gender : nil
			].filter { $0.value != nil }.mapValues({ $0! })
		
		databaseReference.child(authUser.uid).updateChildValues(updates) { (error, ref) in
			guard error == nil else {
				completion(PortlError(error: error, code: PERRCODE_UNKNOWN_FIREBASE_ERROR, message: PERR_UNKNOWN_FIREBASE_ERROR))
				return
			}
			completion(nil)
		}
	}
	
	func searchUserProfiles(withQuery query: String, withCompletion completion: @escaping ([Dictionary<String, Any>]) -> Void) {
		Functions.functions().httpsCallable("search_user_profiles").call(["text":query]) { (result, error) in
			guard error == nil else {
				if let error = error as NSError? {
					let message = error.localizedDescription

					if error.domain == FunctionsErrorDomain,
						let code = FunctionsErrorCode(rawValue: error.code),
						let details = error.userInfo[FunctionsErrorDetailsKey] {
							print("\(code) : \(message) : \(details)")
					} else {
						print(message)
					}
				}
				completion([])
				return
			}

			completion(((result?.data as? [String: Any])?["profiles"] as? [Dictionary<String, Any>]) ?? [])
		}
	}
	
	func getProfile(forUserID userID: String, withCompletion completion: @escaping (Dictionary<String, Any>) -> Void) {
		databaseReference.child(userID).observeSingleEvent(of: .value) { (dataSnapshot) in
			guard let profile = dataSnapshot.value as? Dictionary<String, Any> else {
				return
			}
			completion(profile)
		}
	}
	
	// MARK: Private
	
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
	
	// MARK: Properties (Private)
	
	private let databaseReference = Database.database().reference().child("v2").child(FirebaseKeys.profileKey)
}
