//
//  EventSearch.swift
//  Service
//
//  Created by Jeff Creed on 3/31/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import CoreData

public class EventSearch: Search {
	public var startingWithinDays: Int? {
		get {
			return startingWithinDaysValue?.intValue
		}
		set {
			startingWithinDaysValue = newValue as NSNumber?
		}
	}
}

