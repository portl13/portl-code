//
//  EventKeywordSearch+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension EventKeywordSearch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<EventKeywordSearch> {
        return NSFetchRequest<EventKeywordSearch>(entityName: "EventKeywordSearch")
    }


}
