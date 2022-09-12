//
//  GeocodeService.swift
//  Service
//
//  Created by Jeff Creed on 3/14/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Foundation
import APIEngine
import RxSwift
import CoreLocation

class GeocodeService: Geocoding {
	func getCityName(forLatitude latitude: Double, andLongitude longitude: Double) -> Observable<String?> {
		return geocodeAPI.getCityName(fromLatitude: latitude, andLongitude: longitude).flatMap({[unowned self] (geocodeResponse) -> Observable<String?> in
			return Observable.just(self.getCityNameFromResults(geocodeResults: geocodeResponse))
		})
		.observeOn(MainScheduler.instance)
	}
	
	func getLocation(forAddress address: String) -> Observable<GeocodeLocationAndAddress?> {
		return geocodeAPI.getLocation(fromAddress: address).flatMap({[unowned self] (geocodeResponse) -> Observable<GeocodeLocationAndAddress?> in
			guard geocodeResponse.results.count > 0, let cityName = self.getCityNameFromResults(geocodeResults: geocodeResponse) else {
				return Observable.just(nil)
			}
			
			let result = geocodeResponse.results[0]
			let location = CLLocation(latitude: result.geometry.location.latitude, longitude: result.geometry.location.longitude)
			
			return Observable.just(GeocodeLocationAndAddress(location: location, formattedAddress: cityName))
		})
	}
	
	// MARK: Private
	
	private func getCityNameFromResults(geocodeResults: GeocodeResults) -> String? {
		guard geocodeResults.results.count > 0 else {
			return nil
		}
		
		let result = geocodeResults.results[0]
		
		var country: String?
		var adminArea1: String?
		var locality: String?
		
		result.addressComponents.forEach({ (addressComponent) in
			addressComponent.types.forEach({ (componentType) in
				if componentType == "country" {
					country = addressComponent.name
				} else if componentType == "administrative_area_level_1" {
					adminArea1 = addressComponent.name
				} else if componentType == "locality" {
					locality = addressComponent.name
				}
			})
		})
		
		var cityName: String?
		
		if let country = country {
			if country == "US" {
				if let locality = locality {
					if let adminArea1 = adminArea1 {
						cityName = "\(locality), \(adminArea1)"
					} else {
						cityName = locality
					}
				}
			} else {
				if let locality = locality {
					cityName = "\(locality), \(country)"
				} else if let adminArea1 = adminArea1 {
					cityName = "\(adminArea1), \(country)"
				}
			}
		}
		
		return cityName
	}
	
	// MARK: Init
	
	init(geocodeAPI: GeocodeAPI) {
		self.geocodeAPI = geocodeAPI
	}
	
	// MARK: Properties (Private)
	
	private let geocodeAPI: GeocodeAPI
}
