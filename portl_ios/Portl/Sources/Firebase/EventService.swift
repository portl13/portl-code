//
//  EventService.swift
//  Portl
//
//  Created by Jeff Creed on 3/21/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import RxSwift

class EventService {
	func loadEvent(withEventID eventID: String) {
		eventReference = databaseReference.child(eventID)
		eventHandle = eventReference?.observe(.value, with: {[unowned self] (eventSnapshot) in
			self.event.onNext(EventService.eventFromDataSnapshot(eventSnapshot))
		})
	}
	
	func clearEvent() {
		removeEventHandle()
		event.onNext(nil)
	}
	
	func getEvent(withEventID eventID: String, completion: @escaping (FirebaseEvent?) -> Void) {
		databaseReference.child(eventID).observeSingleEvent(of: .value, with: {(eventSnapshot) in
			completion(EventService.eventFromDataSnapshot(eventSnapshot))
		})
	}
	
	// MARK: Static
	
	static func eventFromDataSnapshot(_ snapshot: DataSnapshot) -> FirebaseEvent? {
		guard snapshot.exists(), let eventData = snapshot.value else {
			return nil
		}
		do {
			let jsonData = try JSONSerialization.data(withJSONObject: eventData, options: [])
			let event = try JSONDecoder().decode(FirebaseEvent.self, from: jsonData)
			return event
		} catch let error {
			print(error)
			return nil
		}
	}
	
	// MARK: Private
	
	private func removeEventHandle() {
		if let reference = eventReference, let handle = eventHandle {
			reference.removeObserver(withHandle: handle)
		}
		eventReference = nil
		eventHandle = nil
	}
	
	// MARK: Init
	
	init(databaseRootReference: DatabaseReference) {
		databaseReference = databaseRootReference.child(FirebaseKeys.eventsKey)
	}
	
	deinit {
		removeEventHandle()
	}
	
	// MARK: Properties
	
	var eventReference: DatabaseReference? = nil
	var eventHandle: DatabaseHandle? = nil
	var event = BehaviorSubject<FirebaseEvent?>(value: nil)
	
	
	// MARK: Properties (private)
	
	private let databaseReference: DatabaseReference!
	
}
