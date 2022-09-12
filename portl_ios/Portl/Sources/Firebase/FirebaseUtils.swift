//
//  FirebaseUtils.swift
//  Portl
//
//  Created by Jeff Creed on 2/8/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

class FirebaseUtils {
	func isSchemaDeprecated(completion: @escaping (String?) -> Void) {
		databaseReference.child(FirebaseKeys.schemaKey).child(FirebaseKeys.SchemaKeys.versionKey).observeSingleEvent(of: .value) {[unowned self] (snapshot) in
			guard let latestSchemaVersion = snapshot.value as? Int else {
				completion(nil)
				return
			}
			if latestSchemaVersion > FirebaseUtils.compatibleFirebaseSchemaVersion {
				self.databaseReference.child(FirebaseKeys.schemaKey).child(FirebaseKeys.SchemaKeys.deprecationDateKey).observeSingleEvent(of: .value, with: { (dateSnapshot) in
					guard let deprecationDateString = dateSnapshot.value as? String, let deprecationDate = self.firebaseValueDateFormatter.date(from: deprecationDateString) else {
						completion(nil)
						return
					}
					let nowDate = Date()
					let ISO8601NowString = ISO8601DateFormatter().string(from: nowDate)
					let deprecationString = "A newer verison of PORTL is avalable. Please update before \(self.dateFormatter.string(from: deprecationDate)), when this version of the app will stop working."
					
					if let lastDepricationWarning = UserDefaults().string(forKey: FirebaseUtils.lastSchemaDeprecationWarningKey), let lastWarningDate = ISO8601DateFormatter().date(from: lastDepricationWarning) {
						if (abs(Calendar.current.dateComponents([.year, .month, .day], from: nowDate, to: lastWarningDate).day!) > 1) {
							FirebaseUtils.updateUserDefaultsLastSchemaWarningDate(dateString: ISO8601NowString)
							completion(deprecationString)
						}
					} else {
						FirebaseUtils.updateUserDefaultsLastSchemaWarningDate(dateString: ISO8601NowString)
						completion(deprecationString)
					}
				})
			} else {
				completion(nil)
			}
		}
	}
	
	private static func updateUserDefaultsLastSchemaWarningDate(dateString: String) {
		UserDefaults().setValue(dateString, forKey: lastSchemaDeprecationWarningKey)
	}
	
	init(notificationDateFormatter: DateFormatter, dateFormatter: DateFormatter) {
		self.firebaseValueDateFormatter = notificationDateFormatter
		self.dateFormatter = dateFormatter
	}
	
	private let databaseReference = Database.database().reference()
	private let firebaseValueDateFormatter: DateFormatter!
	private let dateFormatter: DateFormatter!
	
	private static let compatibleFirebaseSchemaVersion = 2
	private static let lastSchemaDeprecationWarningKey = "lastSchemaDeprecationWarningKey"
}
