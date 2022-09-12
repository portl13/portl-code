//
//  EventsByIDsQuery.swift
//  Service
//
//  Created by Jeff Creed on 5/31/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation

internal struct EventsByIDsQuery: Encodable {
    let id: Array<String>?
    let pageSize: Int
    let page = 0
}
