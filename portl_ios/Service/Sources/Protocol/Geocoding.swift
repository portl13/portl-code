//
//  Geocoding.swift
//  Service
//
//  Created by Jeff Creed on 3/14/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import RxSwift

public protocol Geocoding {
	func getCityName(forLatitude latitude: Double, andLongitude longitude: Double) -> Observable<String?>
	func getLocation(forAddress address: String) -> Observable<GeocodeLocationAndAddress?>
}
