//
//  EventCategoryQuery.swift
//  Service
//
//  Created by Jeff Creed on 4/24/18.
//  Copyright © 2018 Portl. All rights reserved.
//

internal struct EventCategoryQuery: Encodable {
    let location: Location
    let maxDistanceMiles: Double
    let startingAfter: Int64
	let startingWithinDays: Int?
    let categories: Array<String>
    let page: Int
    let pageSize = 100
}
