//
//  FirebasePrivateProfile.swift
//  Portl
//
//  Created by Jeff Creed on 2/4/20.
//  Copyright © 2020 Portl. All rights reserved.
//

import Foundation

public struct FirebasePrivateProfile: Decodable {
	
	public let votes: ProfileVotes?
	
	public struct ProfileVotes: Decodable {
		public let conversation: [String: [String: Bool]]?
		public let experience: [String: [String: Bool]]?
	}
}
