//
//  PortlAPI.swift
//  Service
//
//  Created by Jeff Creed on 4/23/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import Foundation
import APIEngine
import RxSwift
import Alamofire
import RxAlamofire

internal class PortlAPI: BaseAPI, EventAPI, ArtistAPI, VenueAPI {
    func eventCategories() -> Observable<Array<Dictionary<String, Any>>> {
        var urlComponents = baseURLComponents
        urlComponents.path = "/categories"
        
        return apiEngine.createRequestObservable(for: urlComponents, method: .get)
    }
	
	func defaultSelectedCategories() -> Observable<Array<Dictionary<String, Any>>> {
		var urlComponents = baseURLComponents
		urlComponents.path = "/categories/default"
		
		return apiEngine.createRequestObservable(for: urlComponents, method: .get)
	}
	
    func eventByIdentifier(with query: IdQuery) -> Observable<Dictionary<String, Any>> {
        var urlComponents = baseURLComponents
        urlComponents.path = "/events/byId"
        
        return apiEngine.createRequestObservable(for: urlComponents, method: .post, body: query)
    }
    
    func eventCategorySearch(with query: EventCategoryQuery) -> Observable<Dictionary<String, Any>> {
        var urlComponents = baseURLComponents
        urlComponents.path = "/events/search"

        return apiEngine.createRequestObservable(for: urlComponents, method: .post, body: query)
    }
    
    func eventsByIdentifiers(with query: EventsByIDsQuery) -> Observable<Dictionary<String, Any>> {
        var urlComponents = baseURLComponents
        urlComponents.path = "/events"
        
        return apiEngine.createRequestObservable(for: urlComponents, method: .post, body: query)
    }
    
    func artistByIdentifier(with query: IdQuery) -> Observable<Dictionary<String, Any>> {
        var urlComponents = baseURLComponents
        urlComponents.path = "/artists/byId"

        return apiEngine.createRequestObservable(for: urlComponents, method: .post, body: query)
    }
    
    func artistByKeyword(with query: KeywordQuery) -> Observable<Dictionary<String, Any>> {
        var urlComponents = baseURLComponents
        urlComponents.path = "/artists/search"
        
        return apiEngine.createRequestObservable(for: urlComponents, method: .post, body: query)
    }
    
    func venueByIdentifier(with query: IdQuery) -> Observable<Dictionary<String, Any>> {
        var urlComponents = baseURLComponents
        urlComponents.path = "/venues/byId"
        
        return apiEngine.createRequestObservable(for: urlComponents, method: .post, body: query)
    }
    
    func venueByKeyword(with query: KeywordQuery) -> Observable<Dictionary<String, Any>> {
        var urlComponents = baseURLComponents
        urlComponents.path = "/venues/search"
        
        return apiEngine.createRequestObservable(for: urlComponents, method: .post, body: query)
    }
}
