//
//  ArtistKeywordSearch+CoreDataProperties.swift
//  Service
//
//  Created by Jeff Creed on 5/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//
//

import Foundation
import CoreData


extension ArtistKeywordSearch {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ArtistKeywordSearch> {
        return NSFetchRequest<ArtistKeywordSearch>(entityName: "ArtistKeywordSearch")
    }


}
