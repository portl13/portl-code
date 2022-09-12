//
//  ArtistAPI.swift
//  Service
//
//  Created by Jeff Creed on 5/1/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import RxSwift

internal protocol ArtistAPI {
    func artistByIdentifier(with query: IdQuery) -> Observable<Dictionary<String, Any>>
    func artistByKeyword(with query: KeywordQuery) -> Observable<Dictionary<String, Any>>
}
