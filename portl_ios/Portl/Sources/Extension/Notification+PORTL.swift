//
//  Notification+PORTL.swift
//  Portl
//
//  Created by Jeff Creed on 3/15/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation

public extension Notification.Name {
	static let friendListUpdated = Notification.Name(rawValue: "FriendListUpdatedNotification")
	static let livefeedUpdated = Notification.Name(rawValue: "LivefeedUpdatedNotification")
	static let messagesUpdated = Notification.Name(rawValue: "MessagesUpdatedNotification")
	static let authStateChanged = Notification.Name(rawValue: "AuthStateChangedNotification")
	static let openMyFriends = Notification.Name(rawValue: "OpenMyFriendsNotification")
	static let apiDeprecated = Notification.Name(rawValue: "APIDeprecationNotification")
	static let openDirectMessage = Notification.Name(rawValue: "OpenDirectMessageNotification")
}
