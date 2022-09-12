//
//  Interests.swift
//  Portl
//
//  Created by Jeff Creed on 7/4/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation

class Interests {    
    func getCurrentUserInterests(completion: (([Dictionary<String, Any>]) -> Void)? = nil) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            databaseReference.child(FirebaseKeys.profileKey)
                .child(currentUserID)
                .child(FirebaseKeys.ProfileKeys.interestsKey)
                .observeSingleEvent(of: .value) {(snapshot) in
                    guard let interests = snapshot.value as? [Dictionary<String, Any>] else {
                        completion?([])
                        return
                    }
                    completion?(interests)
            }
        }
    }
    
    func updateUserInterests(with interests: [Dictionary<String, Any>], completion: ((Error?) -> Void)? = nil) {
        if let currentUserID = Auth.auth().currentUser?.uid {
            databaseReference.child(FirebaseKeys.profileKey)
                .child(currentUserID)
                .updateChildValues([FirebaseKeys.ProfileKeys.interestsKey: interests]) { (error, databaseRef) in
                    completion?(error)
            }
        }
    }
    
    private let databaseReference = Database.database().reference().child("v2")
}
