//
//  FriendsController.swift
//  Portl
//
//  Created by Jeff Creed on 8/9/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CSkyUtil
import Service
import CoreData
import RxSwift

@objc public class FriendsController: NSObject {
	@objc func loadFriends() {
		friends.loadFriendships()
	}
	
	// MARK: Init
	
	public override init() {
		super.init()
		Injector.root!.inject(into: inject)
	}
	
	private func inject(friends: Friends) {
		self.friends = friends
	}
	
	// MARK: Properties (Private)
	
	private var friends: Friends!
}
