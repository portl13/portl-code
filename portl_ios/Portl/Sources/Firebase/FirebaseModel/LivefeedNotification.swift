//
//  LivefeedNotification+CoreDataClass.swift
//  Service
//
//  Created by Jeff Creed on 5/30/19.
//  Copyright © 2019 Portl. All rights reserved.
//
//

import Foundation
import CoreData

@objc(LivefeedNotification)
public class LivefeedNotification: NSManagedObject {
	public var notificationType: NotificationType { return NotificationType.init(rawValue: notificationTypeValue)! }
	
	public enum NotificationType: String {
		case share = "s"
		case going = "g"
		case interested = "i"
		case community = "c"
		case reply = "r"
		case experience = "e"
	}
}
