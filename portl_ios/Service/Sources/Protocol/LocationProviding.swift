//
//  LocationProviding.swift
//  Service
//
//  Created by Jeff Creed on 4/18/18.
//  Copyright © 2018 Portl. All rights reserved.
//
import CoreLocation

public protocol LocationProviding {
    func performAuthorizedLocationAccess(with completion: @escaping (Bool) -> Void)
    var currentLocation: CLLocation? { get }
	
	static var metersPerMile: Double { get }
}
