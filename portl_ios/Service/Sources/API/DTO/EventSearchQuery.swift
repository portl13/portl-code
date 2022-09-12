//
//  EventSearchQuery.swift
//  Service
//
//  Created by Jeff Creed on 4/19/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation

internal struct EventSearchQuery: Encodable {
    let location: Location
    let maxDistanceMiles: Double?
    let startingAfter: Int64?
    let startingWithinDays: Int?
    let categories: Array<String>?
    let page: Int
    let pageSize = 100
}
