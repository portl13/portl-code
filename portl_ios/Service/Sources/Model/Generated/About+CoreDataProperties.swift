//
//  About+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 4/8/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension About {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<About> {
        return NSFetchRequest<About>(entityName: "About")
    }

    @NSManaged public var markupType: String
    @NSManaged public var value: String
    @NSManaged public var artist: PortlArtist?
    @NSManaged public var event: PortlEvent?

}
