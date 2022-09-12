//
//  LocationService.swift
//  Service
//
//  Created by Jeff Creed on 4/18/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CoreLocation
import UIKit

public extension Notification.Name {
	static let locationUpdateNotification = Notification.Name(rawValue: "LocationUpdateNotification")
}

class LocationService: NSObject, LocationProviding, CLLocationManagerDelegate {
    // MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        let authorized = status == .authorizedAlways || status == .authorizedWhenInUse
        if authorized {
            self.startLocationManager()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // todo??
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations[0]
        
        if let location = currentLocation {
            if location.distance(from: newLocation) > LocationService.minimumLocationDifferenceMeters {
                currentLocation = newLocation
                postUpdateNotification()
            }
        } else {
            currentLocation = newLocation
            postUpdateNotification()
        }
    }
    
    // MARK: Public
    
    public func performAuthorizedLocationAccess(with completion: @escaping (Bool) -> Void) {
        // check location authorized
        let authorizationStatus = CLLocationManager.authorizationStatus()
        if authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            completion(false)
        }
        else {
            let authorized = authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
            completion(authorized)
        }
    }
    
    // MARK: Private
    
    private func postUpdateNotification() {
        NotificationCenter.default.post(name: .locationUpdateNotification, object: self)
    }
    
    private func startLocationManager() {
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager?.startUpdatingLocation()
    }
    
    private func stopLocationManager() {
        locationManager?.stopUpdatingLocation()
        locationManager?.delegate = nil
    }
    
    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager

        super.init()
        
        startLocationManager()
    }
    
    deinit {
        stopLocationManager()
    }
    
    
    private static let minimumLocationDifferenceMeters: Double = 1000.0
    
    public var currentLocation: CLLocation?

    private var locationManager: CLLocationManager!
	
	public static let metersPerMile = 1609.34
}
