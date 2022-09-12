//
//  GoogleGeocodeAPI.swift
//  Service
//
//  Created by Jeff Creed on 3/14/19.
//  Copyright © 2019 Portl. All rights reserved.
//

import Alamofire
import APIEngine
import RxSwift

internal class GoogleGeocodeAPI: BaseAPI, GeocodeAPI {
	func getCityName(fromLatitude latitude: Double, andLongitude longitude: Double) -> Observable<GeocodeResults> {
		var urlComponents = baseURLComponents
		urlComponents.path += "/geocode/json"
		urlComponents.queryItems = [URLQueryItem(name: "latlng", value: "\(latitude),\(longitude)"), URLQueryItem(name: "key", value: apiKey)]
		
		return apiEngine.createRequestObservable(for: urlComponents, method: .get, body: nil)

	}
	
	func getLocation(fromAddress address: String) -> Observable<GeocodeResults> {
		var urlComponents = baseURLComponents
		urlComponents.path += "/geocode/json"
		urlComponents.queryItems = [URLQueryItem(name: "address", value: "\(address)"), URLQueryItem(name: "key", value: apiKey)]
		
		return apiEngine.createRequestObservable(for: urlComponents, method: .get, body: nil)
	}
	
	init(apiKey: String, apiEngine: APIEngine, baseURLComponents: URLComponents) {
		self.apiKey = apiKey
		super.init(apiEngine: apiEngine, baseURLComponents: baseURLComponents)
	}
	
	private let apiKey: String
}
