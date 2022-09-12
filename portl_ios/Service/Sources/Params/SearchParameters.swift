//
//  SearchParameters.swift
//  Service
//
//  Created by Jeff Creed on 5/5/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CoreLocation

public struct SearchParameters: Equatable {
    public var location: CLLocation?
    public var distance: Double?
	public var startingDate: Date?
	public var adjustedDate: Date? {
		guard startingDate != nil else {
			return nil
		}
		return hoursOffsetFromLocation != 0 ? Calendar.current.date(byAdding: .hour, value: hoursOffsetFromLocation ?? 0, to: startingDate!)! : startingDate
	}
	public var locationName: String?
	
    public var categories: Array<PortlCategory>?
	public var hoursOffsetFromLocation: Int?
	
    public init() {
        // empty params object
    }
    
    public init(categories: Array<PortlCategory>) {
        self.categories = categories
    }
    
	public init(location: CLLocation?, distance: Double?, startingDate: Date?, categories: Array<PortlCategory>?, hoursOffsetFromLocation: Int?, locationName: String?) {
        self.location = location
        self.distance = distance
        self.startingDate = startingDate
        self.categories = categories
		self.hoursOffsetFromLocation = hoursOffsetFromLocation
		self.locationName = locationName
    }
    
    public static func == (lhs: SearchParameters, rhs: SearchParameters) -> Bool {
        return lhs.categories == rhs.categories && lhs.location == rhs.location && lhs.distance == rhs.distance && lhs.startingDate == rhs.startingDate
    }
}

