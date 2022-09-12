//
//  HomeParametersService.swift
//  Service
//
//  Created by Jeff Creed on 4/11/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import RxSwift

public class HomeParametersService: SearchParametersProviding {
	public func updateSearchParameters(_ params: SearchParameters) {
		let newParams = SearchParameters(location: params.location ?? previousSearchParams.location,
										 distance: params.distance ?? previousSearchParams.distance,
										 startingDate: params.startingDate ?? previousSearchParams.startingDate,
										 categories: params.categories ?? previousSearchParams.categories,
										 hoursOffsetFromLocation: params.hoursOffsetFromLocation ?? previousSearchParams.hoursOffsetFromLocation,
										 locationName: params.locationName ?? previousSearchParams.locationName
		)
		
		
		if newParams != previousSearchParams {
			previousSearchParams = newParams
			currentSearchParams.onNext(newParams)
		}
	}
	
	// MARK: Initialization
	
	public init() {
		currentSearchParams = BehaviorSubject<SearchParameters?>(value:
			SearchParameters(location: nil,
							 distance: nil,
							 startingDate: nil,
							 categories: nil,
							 hoursOffsetFromLocation: 0,
							 locationName: nil
			)
		)
		previousSearchParams = SearchParameters()
	}
	
	// MARK: Properties
	
	public var currentSearchParams: BehaviorSubject<SearchParameters?>
	public var distanceForSearch: Double = 25
	
	// MARK: Properties (Private)
	
	private var previousSearchParams: SearchParameters
}
