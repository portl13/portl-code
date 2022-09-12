//
//  EventAPI.swift
//  Service
//
//  Created by Jeff Creed on 4/19/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import RxSwift
import CoreData

internal protocol EventAPI {
    func eventCategorySearch(with query: EventCategoryQuery) -> Observable<Dictionary<String, Any>>
    func eventByIdentifier(with query: IdQuery) -> Observable<Dictionary<String, Any>>
    func eventsByIdentifiers(with query: EventsByIDsQuery) -> Observable<Dictionary<String, Any>>
}
