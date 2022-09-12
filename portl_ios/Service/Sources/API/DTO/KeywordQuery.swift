//
//  KeywordQuery.swift
//  Service
//
//  Created by Jeff Creed on 5/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//

internal struct KeywordQuery: Encodable {
    let name: String
	let page: Int
	let location: Location?
	let maxDistanceMiles: Double?
    let pageSize = 50
	
	init(name: String, page: Int, location: Location? = nil, withinDistance: Double? = nil) {
		self.name = name
		self.page = page
		self.location = location
		self.maxDistanceMiles = withinDistance
	}
}
