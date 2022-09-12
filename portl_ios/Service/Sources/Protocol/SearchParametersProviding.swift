//
//  SearchParametersProviding.swift
//  Service
//
//  Created by Jeff Creed on 4/10/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CoreLocation
import RxSwift

public protocol SearchParametersProviding {
    func updateSearchParameters(_ params: SearchParameters) -> Void
    var currentSearchParams: BehaviorSubject<SearchParameters?> { get }
	var distanceForSearch: Double { get }
}
