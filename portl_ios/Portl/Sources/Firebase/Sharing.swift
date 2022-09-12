//
//  Sharing.swift
//  Portl
//
//  Created by Jeff Creed on 6/5/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Service

class Sharing {
    func hasShared(event: PortlEvent, completion: @escaping (Bool) -> Void) {
        databaseReference.child(FirebaseKeys.profileKey)
            .child(portlAuthenicator.currentUser().uid)
            .child(FirebaseKeys.ProfileKeys.sharedKey)
            .child(event.identifier)
            .observeSingleEvent(of: .value, with: { snapshot in
            completion(snapshot.value != nil)
        })
    }
    
    func share(event: PortlEvent, withFriendIDs friendIDs: Array<String>) {
        let userID = portlAuthenicator.currentUser().uid
        
        // put / update in profile
        
        databaseReference.child(FirebaseKeys.profileKey)
            .child(userID)
            .child(FirebaseKeys.ProfileKeys.sharedKey)
            .child(event.identifier)
            .setValue(dateFormatter.string(from: Date()))
        
        guard friendIDs.count > 0 else {
            return
        }
	}
    
    init(dateFormatter: FirebaseDateFormatter) {
        self.dateFormatter = dateFormatter.value
    }
    
    let databaseReference = Database.database().reference()
    let portlAuthenicator = FIRPortlAuthenticator.shared()!
    let dateFormatter: DateFormatter!
}
