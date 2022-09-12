//
//  GoogleGeocodeResult.swift
//  Service
//
//  Created by Jeff Creed on 3/14/19.
//  Copyright © 2019 Portl. All rights reserved.
//

internal struct Coordinates: Decodable {
	let latitude: Double
	let longitude: Double
	
	private enum CodingKeys: String, CodingKey {
		case latitude = "lat"
		case longitude = "lng"
	}
}

internal struct Geometry: Decodable {
	let location: Coordinates
}

internal struct AddressComponent: Decodable {
	let name: String
	let types: Array<String>
	
	private enum CodingKeys: String, CodingKey {
		case name = "short_name"
		case types
	}
}

internal struct Result: Decodable {
	let addressComponents: Array<AddressComponent>
	let geometry: Geometry
	let formattedAddress: String
	
	private enum CodingKeys: String, CodingKey {
		case addressComponents = "address_components"
		case geometry
		case formattedAddress = "formatted_address"
	}
}

internal struct GeocodeResults: Decodable {
	let results: Array<Result>
}
