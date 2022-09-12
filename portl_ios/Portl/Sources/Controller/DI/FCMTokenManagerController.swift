//
//  FCMTokenManagerController.swift
//  Portl
//
//  Created by Jeff Creed on 6/19/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import CSkyUtil


@objc public class FCMTokenManagerController: NSObject {
	@objc func setFCMTokenAfterLogin() {
		fcmTokenManager.retriveTokenFromInstanceNow()
	}
	
	// MARK: Init
	
	override public init() {
		super.init()
		Injector.root!.inject(into: inject)
	}
	
	private func inject(fcmTokenManager: FCMTokenManager) {
		self.fcmTokenManager = fcmTokenManager
	}
	
	// MARK: Properties (Private)
	
	private var fcmTokenManager: FCMTokenManager!

}
