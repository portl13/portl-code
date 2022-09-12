//
//  ProfileServiceController.swift
//  Portl
//
//  Created by Jeff Creed on 6/5/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil

class ProfileServiceController: NSObject {
	
	@objc func getLivefeedNotificationCount() {
		if let profile = try? userProfileService.authenticatedProfile.value() {
			let count = profile.unseenLivefeed?.count ?? 0
			let payload = NSNumber(value: count)
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: Notification.Name(gNotificationNotificationListUpdated), object: nil, userInfo: ["count": payload as Any])
			}
		}
	}
	
	@objc func getUnreadMessagesCount() {
		if let profile = try? userProfileService.authenticatedProfile.value() {
			let count = profile.unreadMessages?.count ?? 0
			let payload = NSNumber(value: count)
			DispatchQueue.main.async {
				NotificationCenter.default.post(name: Notification.Name(gNotificationMessageRoomsUpdated), object: nil, userInfo: ["count": payload as Any])
			}
		}
	}
	
	@objc func getProfileBio() -> String? {
		return userProfileService.getProfileBio()
	}
	
	@objc func setProfileBio(bioText: String, completion:((PortlError?) -> Void)?) {
		userProfileService.updateBio(bioText: bioText) { (error) in
			completion?(error)
		}
	}
	
	// MARK: Init
	
	override public init() {
		super.init()
		Injector.root!.inject(into: inject)
	}
	
	private func inject(userProfileService: UserProfileService) {
		self.userProfileService = userProfileService
	}
	
	// MARK: Properties (Private)
	
	private var userProfileService: UserProfileService!
}
