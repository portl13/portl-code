//
//  LocationServiceProviderContainer.swift
//  Service
//
//  Created by Jeff Creed on 4/19/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CoreLocation
import CSkyUtil

public class LocationServiceProviderContainer: ProviderContainer {
    override public init() {
        super.init()
        
        self.provide(type: CLLocationManager.self).with { CLLocationManager() }
        self.provide(type: LocationProviding.self).asSingleton().with { (locationManager: CLLocationManager) in LocationService(locationManager: locationManager) }
    }
}
