//
//  RootTabBarController.swift
//  Portl
//
//  Created by Jeff Creed on 3/14/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CSkyUtil

class NewRootTabBarController: UITabBarController {
	// MARK: Enum
	
	enum TabIndex: Int, CaseIterable {
		case home = 1
		case bookmarks
		case messages
		case connect
		case livefeed
	}
	
	// MARK: Private
	
	private func configureTabs() {
		let homeNavController = UIStoryboard(name: "home", bundle: nil).instantiateViewController(withIdentifier: "HomeScene")
		homeNavController.tabBarItem.title = "Home"
		homeNavController.tabBarItem.image = UIImage(named: "icon_tab_bar_home")
		
		let messagesNavController = UINavigationController(rootViewController: viewController(forTabIndex: .messages))
		messagesNavController.tabBarItem.title = "Messages"
		messagesNavController.tabBarItem.image = UIImage(named: "icon_tab_bar_messages")
		
		let bookmarksNavController = UINavigationController(rootViewController: viewController(forTabIndex: .bookmarks))
		bookmarksNavController.tabBarItem.title = "Bookmarks"
		bookmarksNavController.tabBarItem.image = UIImage(named: "icon_tab_bar_bookmarks")
		
		let connectNavController = UINavigationController(rootViewController: viewController(forTabIndex: .connect))
		connectNavController.tabBarItem.title = "Connect"
		connectNavController.tabBarItem.image = UIImage(named: "icon_tab_bar_connect")
		
		let livefeedNavController = UINavigationController(rootViewController: viewController(forTabIndex: .livefeed))
		livefeedNavController.tabBarItem.title = "Livefeed"
		livefeedNavController.tabBarItem.image = UIImage(named: "icon_tab_bar_livefeed")
		
		self.viewControllers = [homeNavController, messagesNavController, bookmarksNavController, connectNavController, livefeedNavController]
		self.tabBar.unselectedItemTintColor = PaletteColor.light1.uiColor.withAlphaComponent(0.5)
		self.tabBar.tintColor = PaletteColor.light1.uiColor
		self.tabBar.backgroundColor = PaletteColor.dark3.uiColor
		self.tabBar.clipsToBounds = true
	}
	
	private func updateViewControllersForAuthenticationStateChange() {
		for index in TabIndex.allCases {
			let navController = viewControllers![index.rawValue] as! UINavigationController
			navController.viewControllers = [viewController(forTabIndex: index)]
		}
	}
	
	private func viewController(forTabIndex idx: TabIndex) -> UIViewController {
		if let user = Auth.auth().currentUser, !user.isAnonymous {
			return authenticateViewController(forTabIndex:idx)
		} else {
			return nonAuthenticatedViewController(forTabIndex:idx)
		}
	}
	
	private func authenticateViewController(forTabIndex idx: TabIndex) -> UIViewController {
		switch idx {
		case .home:
			break
		case .bookmarks:
			return UIStoryboard(name: "favorite", bundle: nil).instantiateViewController(withIdentifier: "FavoritesHomeViewController")
		case .messages:
			return UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "MessagesHomeViewController")
		case .connect:
			return UIStoryboard(name: "connect", bundle: nil).instantiateViewController(withIdentifier: "ConnectHomeViewController")
		case .livefeed:
			return UIStoryboard(name: "notification", bundle: nil).instantiateViewController(withIdentifier: "LivefeedListViewController")
		}
		return UIViewController()
	}
	
	private func nonAuthenticatedViewController(forTabIndex idx: TabIndex) -> UIViewController {
		let authRequiredViewController = UIStoryboard(name: "common", bundle: nil).instantiateViewController(withIdentifier: "AuthRequiredViewController") as! AuthRequiredViewController
		switch idx {
		case .home:
			break
		case .bookmarks:
			authRequiredViewController.message = "You must sign in to manage your bookmarks."
		case .messages:
			authRequiredViewController.message = "You must sign in to send or receive messages"
		case .connect:
			authRequiredViewController.message = "You must sign in to manage your connections."
		case .livefeed:
			authRequiredViewController.message = "You must sign in to view your livefeed."
		}
		return authRequiredViewController
	}
	
	private func openFriends() {
		let navController = viewControllers![TabIndex.connect.rawValue] as! UINavigationController
		navController.popToRootViewController(animated: false)
		let connectViewController = navController.viewControllers[0] as! ConnectHomeViewController
		connectViewController.segmentIndex = 1
		selectedIndex = 3
	}
	
	private func onRefreshMessagesBadge() {
		/*
		TODO:
		if ([[FIRMessagesManager sharedManager] newMessageRooms] > 0) {
		self.viewControllers[2].tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [[FIRMessagesManager sharedManager] newMessageRooms]];
		} else {
		self.viewControllers[2].tabBarItem.badgeValue = nil;
		}

		*/
	}
	
	private func onRefreshFriendsBadge() {
		/*
		TODO:
		if ([[FIRFriends sharedFriends] friendsCountWaitingForAcceptance] > 0) {
		self.viewControllers[3].tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [[FIRFriends sharedFriends] friendsCountWaitingForAcceptance]];;
		} else {
		self.viewControllers[3].tabBarItem.badgeValue = nil;
		}

		*/
	}
	
	private func onRefreshLivefeedBadge() {
		/*
		TODO:
		if ([[FIRNotificationManager sharedManager] unreadNotificationsCount] > 0) {
		self.viewControllers[4].tabBarItem.badgeValue = [NSString stringWithFormat:@"%d", [[FIRNotificationManager sharedManager] unreadNotificationsCount]];;
		} else {
		self.viewControllers[4].tabBarItem.badgeValue = nil;
		}

		*/
	}
	
	private func receivedAPIDeprecationWarning(_ notification: Notification) {
		if let userInfo = notification.userInfo, let message = userInfo["message"] as? String {
			presentErrorAlert(withMessage: message, completion: nil)
		}
	}
	
	private func openDirectMessage(_ notification: Notification) {
		if let userInfo = notification.userInfo, let username = userInfo["username"] as? String, let conversationKey = userInfo["conversationKey"] as? String {
			let navController = viewControllers![TabIndex.messages.rawValue] as! UINavigationController
			navController.popToRootViewController(animated: false)
			let directMessageViewController = UIStoryboard(name: "message", bundle: nil).instantiateViewController(withIdentifier: "DirectConversationViewController") as! DirectConversationViewController
			directMessageViewController.conversationKey = conversationKey
			directMessageViewController.username = username
			selectedIndex = 3
			navController.pushViewController(directMessageViewController, animated: false)
		}
	}
	
	// MARK: View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		configureTabs()
		
		NotificationCenter.default.addObserver(forName: .friendListUpdated, object: nil, queue: nil) { (_) in
			self.onRefreshFriendsBadge()
		}
		NotificationCenter.default.addObserver(forName: .livefeedUpdated, object: nil, queue: nil) { (_) in
			self.onRefreshLivefeedBadge()
		}
		NotificationCenter.default.addObserver(forName: .messagesUpdated, object: nil, queue: nil) { (_) in
			self.onRefreshMessagesBadge()
		}
		NotificationCenter.default.addObserver(forName: .authStateChanged, object: nil, queue: nil) { (_) in
			self.updateViewControllersForAuthenticationStateChange()
		}
		NotificationCenter.default.addObserver(forName: .openMyFriends, object: nil, queue: nil) { (_) in
			self.openFriends()
		}
		NotificationCenter.default.addObserver(forName: .apiDeprecated, object: nil, queue: nil) { (notification) in
			self.receivedAPIDeprecationWarning(notification)
		}
		NotificationCenter.default.addObserver(forName: .openDirectMessage, object: nil, queue: nil) { (notification) in
			self.openDirectMessage(notification)
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if shouldCheckFirebaseSchemaVersion {
			shouldCheckFirebaseSchemaVersion = false
			firebaseUtils.isSchemaDeprecated {[unowned self] (message) in
				if let message = message {
					self.presentErrorAlert(withMessage: message, completion: nil)
				}
			}
		}
	}
	
	// MARK: Init
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		Injector.root!.inject(into: inject)
	}
	
	private func inject(firebaseUtils: FirebaseUtils) {
		self.firebaseUtils = firebaseUtils
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: Properties (Private)
	
	private var shouldCheckFirebaseSchemaVersion = true
	private var firebaseUtils: FirebaseUtils!
}
