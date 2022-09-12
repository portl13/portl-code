//
//  GeoCodeLocationAndAddress.swift
//  Service
//
//  Created by Jeff Creed on 3/14/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import CoreLocation

public struct GeocodeLocationAndAddress {
	public let location: CLLocation
	public let formattedAddress: String
}
