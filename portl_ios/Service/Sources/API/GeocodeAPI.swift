//
//  GeocodeAPI.swift
//  Service
//
//  Created by Jeff Creed on 3/14/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import RxSwift

internal protocol GeocodeAPI {
	func getCityName(fromLatitude latitude: Double, andLongitude longitude: Double) -> Observable<GeocodeResults>
	func getLocation(fromAddress address: String) -> Observable<GeocodeResults>
}
