//
//  AppDelegate.swift
//  Portl
//
//  Created by Jeff Creed on 3/26/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseInstanceID
import FirebaseMessaging
import FirebaseAnalytics
import UserNotifications
import CSkyUtil
import Service
import CoreData
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    // MARK: Public
	func inject(UIService: AppearanceConfiguring, profileService: UserProfileService, fcmTokenManager: FCMTokenManager) {
        self.UIService = UIService
		self.fcmTokenManager = fcmTokenManager
		
		// initialize profile service singleton to catch auth state change
		self.profileService = profileService
    }
    
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		configureFirebase(application: application)

        let injector = Injector(providerContainers: [PortlServiceProviderContainer(), GeneralProviderContainer(), SearchParamsProviderContainer(), LocationServiceProviderContainer()])
		Injector.root = injector
        injector.inject(into: inject)
        
        UIService.configureAppearance()
        
        return true
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable ro register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		print("APNs token retrieved: \(deviceToken)")
        Messaging.messaging().apnsToken = deviceToken
	}
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("Received notification with \(userInfo)")
		Messaging.messaging().appDidReceiveMessage(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("Received notification with \(userInfo)")
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler(.newData)
	}
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("User Notification Center will present notification body: \(notification.request.content.body) title: \(notification.request.content.title) userInfo: \(notification.request.content.userInfo)")
        CMNavBarNotificationView.notify(withText: notification.request.content.title, andDetail: notification.request.content.body)
    }
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		let notificationUserInfo = response.notification.request.content.userInfo
		
		if let notificationType = notificationUserInfo["notification_type"] as? String {
			switch notificationType {
			case "f":
				NotificationCenter.default.post(name: Notification.Name(gNotificationOpenMyFriends), object: nil, userInfo: ["show_notifications": true])
			case "e":
				fallthrough
			case "i":
				fallthrough
			case "m":
				guard let conversationKey = notificationUserInfo["conversation_id"], let senderUsername = notificationUserInfo["sender_username"] else {
					break
				}
				NotificationCenter.default.post(name: Notification.Name(gNotificationOpenDirectMessage), object: nil, userInfo: ["username": senderUsername, "conversationKey": conversationKey])
			default:
				break
			}
		}
		
		completionHandler()
	}
	
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Application received remote message: \(remoteMessage.appData)")
        if let data = remoteMessage.appData["notification"] as? [String : String] {
            CMNavBarNotificationView.notify(withText: data["title"], andDetail: data["body"])
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
		print("Firebase registration token: \(fcmToken)")
	}
    
    func configureFirebase(application: UIApplication) {
		FirebaseApp.configure()
		
		Messaging.messaging().delegate = self
		
		#if (STAGING && QA) || !STAGING
			Fabric.with([Crashlytics.self])
		#endif
		
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: {_, _ in})

        application.registerForRemoteNotifications()
    }
	
    
    // MARK: Properties (UIApplicationDelegate)
    var window: UIWindow?
    
    // MARK: Properties (Injected)
    private var UIService: AppearanceConfiguring!
	private var profileService: UserProfileService!
	private var fcmTokenManager: FCMTokenManager!
}
