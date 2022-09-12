//
//  VenueAPI.swift
//  Service
//
//  Created by Jeff Creed on 5/7/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import RxSwift

internal protocol VenueAPI {
    func venueByIdentifier(with query: IdQuery) -> Observable<Dictionary<String, Any>>
    func venueByKeyword(with query: KeywordQuery) -> Observable<Dictionary<String, Any>>
}
