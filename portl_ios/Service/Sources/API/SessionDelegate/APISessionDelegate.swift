//
//  APISessionDelegate.swift
//  Service
//
//  Created by Jeff Creed on 12/10/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Alamofire
import CSkyUtil

internal class APISessionDelegate: SessionDelegate {
	init(deprecationDateFormatter: APIDeprecationDateFormatterQualifier) {
		self.deprecationDateFormatter = deprecationDateFormatter.value
		super.init()
		
		taskDidComplete = {[unowned self] urlSession, urlSessionTask, error in
			guard error == nil else {
				return
			}
			let headers = (urlSessionTask.response as! HTTPURLResponse).allHeaderFields
			if let deprecationDateString = headers[APISessionDelegate.deprecationWarningHeaderKey] as? String, let deprecationDate = ISO8601DateFormatter().date(from: deprecationDateString) {
				let deprecationDateHumanString = self.deprecationDateFormatter.string(from: deprecationDate)
				let nowDate = Date()
				let ISO8601NowString = ISO8601DateFormatter().string(from: nowDate)
				
				if let lastDepricationWarning = UserDefaults().string(forKey: APISessionDelegate.lastDeprecationWarningKey), let lastWarningDate = ISO8601DateFormatter().date(from: lastDepricationWarning) {
					if (abs(Calendar.current.dateComponents([.year, .month, .day], from: nowDate, to: lastWarningDate).day!) > 1) {
						APISessionDelegate.postAPIDeprecationNotification(nowString: ISO8601NowString, deprecationDateString: deprecationDateHumanString)
					}
				} else {
					APISessionDelegate.postAPIDeprecationNotification(nowString: ISO8601NowString, deprecationDateString: deprecationDateHumanString)
				}
			}
		}
	}
	
	private var deprecationDateFormatter: DateFormatter

	private static func postAPIDeprecationNotification(nowString: String, deprecationDateString: String) {
		UserDefaults().setValue(nowString, forKey: lastDeprecationWarningKey)
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: Notification.Name("gNotificationApiDeprecation"), object: nil, userInfo: [deprecationNotificationMessageKey: "A newer verison of PORTL is avalable. Please update before \(deprecationDateString), when this version of the app will stop working."])
		}
	}
	
	private static let lastDeprecationWarningKey = "lastAPIDeprecationWarning"
	private static let deprecationWarningHeaderKey = "x-api-deprecation-date"
	private static let deprecationNotificationMessageKey = "message"
}
