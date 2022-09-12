//
//  PortlService.swift
//  Service
//
//  Created by Charles Augustine on 3/20/18.
//  Copyright © 2018 Portl. All rights reserved.
//


import Foundation
import CoreData
import RxSwift
import CSkyUtil
import CoreLocation
import Alamofire
import RxAlamofire
import APIService

protocol ProvidesLocalStartDateFormatter {
	func getLocalStartDate(fromString string: String) -> NSDate
}


class PortlService: BaseCoreDataService, PortlDataProviding, ProvidesLocalStartDateFormatter {
	
	func clearCachedEvents() {
		deleteAllObjects(PortlEvent.entity().name!)
		deleteAllObjects(EventSearch.entity().name!)
		try? persistentContainer.viewContext.save()
	}
	
	private func deleteAllObjects(_ entity:String) {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
		fetchRequest.returnsObjectsAsFaults = false
		do {
			let results = try persistentContainer.viewContext.fetch(fetchRequest)
			for object in results {
				guard let objectData = object as? NSManagedObject else {continue}
				persistentContainer.viewContext.delete(objectData)
			}
		} catch let error {
			print("Delete all data in \(entity) error :", error)
		}
	}

	// MARK: PORTL DATA
	// MARK: Requests (Categories)
    
    func getPortlCategories() -> Observable<Void> {
        let context = persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
        let fetchRequest: NSFetchRequest<PortlCategory> = PortlCategory.fetchRequest()
        var currentCategories = Array<PortlCategory>()
        var toRemove = Set<PortlCategory>()
    
        do {
            currentCategories = try context.fetch(fetchRequest)
            toRemove = Set(currentCategories)
        } catch {
            print("Error finding existing categories")
        }
		
		let defaultCategoriesObservable = portlAPI.defaultSelectedCategories()
		let allCategoriesObservable = portlAPI.eventCategories()
		
		return Observable.zip(defaultCategoriesObservable, allCategoriesObservable, resultSelector: { (allDefaultCategoryValues, allCategoryValues) in
			var categoryEntities = Array<PortlCategory>()

			for (idx, var catValues) in allDefaultCategoryValues.enumerated() {
				catValues["idx"] = Int64(idx)
				catValues["selected"] = true
				let categoryEntitiy = try self.deserializeEntity(of: PortlCategory.self, forJson: catValues, inContext: context, shouldSave: false)
				categoryEntities.append(categoryEntitiy!)
			}
			
			var seenDisplayNames = [String: String]()
			let seenNames: [String] = categoryEntities.map {
				seenDisplayNames[$0.name] = $0.display
				return $0.name
			}
			
			for var catValues in allCategoryValues {
				if !seenNames.contains(catValues["name"] as! String) || seenDisplayNames[catValues["name"] as! String] != (catValues["display"] as! String) {
					catValues["idx"] = Int64(categoryEntities.count)
					catValues["selected"] = false
					let categoryEntitiy = try self.deserializeEntity(of: PortlCategory.self, forJson: catValues, inContext: context, shouldSave: false)
					categoryEntities.append(categoryEntitiy!)
				}
			}
			
			for validCategory in categoryEntities {
				toRemove.remove(validCategory)
			}
			
			if toRemove.count > 0 || categoryEntities.count > currentCategories.count {
				for invalidCategory in toRemove {
					context.delete(invalidCategory)
				}
				try context.save()
			} else {
				context.rollback()
			}
		})
    }
    
    // MARK: Requests (Event)
    
	func getEvents(forCategory category: String, location: CLLocation, distance: Double, startDate: Date, withinDays: Int?, page: Int) -> Observable<NSManagedObjectID> {
		return getEvents(forCategories: [category], location: location, distance: distance, startDate: startDate, withinDays: withinDays, page: page)
    }
    
	func getEvents(forCategories categories: Array<String>, location: CLLocation, distance: Double, startDate: Date, withinDays: Int?, page: Int) -> Observable<NSManagedObjectID> {
		let context = persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

		let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        
        // check for in-flight observable
        
		let cacheHash = "\(latitude)\(longitude)\(startDate)\(withinDays ?? -1)\(distance)100\(categories.joined())"
        
        if let inFlight = inFlightSearchObservables[cacheHash] {
            return inFlight
        }
        
        // look in core data
        
        if let cached = checkCache(for: EventSearch.self, withPredicate:  EventSearch.predicateForCacheLookup(latitude: latitude,
                                                                                                              longitude: longitude,
                                                                                                              date: startDate,
                                                                                                              startingWithin: withinDays,
                                                                                                              distance: distance,
                                                                                                              pageSize: 100,
																											  categories: categories.joined()), inContext: context) {
            return Observable.just(cached.objectID)
        }
        
        let eventCategoryQuery = EventCategoryQuery(location: Location(lat: latitude, lng: longitude),
                                                    maxDistanceMiles: distance,
                                                    startingAfter: Int64(startDate.timeIntervalSince1970),
													startingWithinDays: withinDays,
                                                    categories: categories,
                                                    page: page)
        
        let observable = portlAPI.eventCategorySearch(with: eventCategoryQuery)
            .flatMap({ [unowned self] (json) -> Observable<NSManagedObjectID> in
				let searchEntity = try self.deserializeAndSaveEntity(of: EventSearch.self, forJson: json, inContext: context)
                self.inFlightSearchObservables.removeValue(forKey: cacheHash)
                return Observable.just(searchEntity!.objectID)
            })
            .observeOn(MainScheduler.instance)
        
        inFlightSearchObservables[cacheHash] = observable
        return observable
    }
	
	func getEvent(forIdentifier identifier: String) -> Observable<NSManagedObjectID> {
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		
		// check for in-flight observable
		
		if let inFlight = inFlightEventObservables[identifier] {
			return inFlight
		}
		
		// look in core data
		
		if let cached = checkCache(for: PortlEvent.self, withPredicate: PortlEvent.predicateForCacheLookup(identifier: identifier), inContext: context) {
			return Observable.just(cached.objectID)
		}
		
		let observable = portlAPI.eventByIdentifier(with: IdQuery(identifier: identifier))
			.flatMap({ [unowned self] (json) -> Observable<NSManagedObjectID> in
				let event = try self.deserializeAndSaveEntity(of: PortlEvent.self, forJson: json, inContext: context)
				self.inFlightEventObservables.removeValue(forKey: identifier)
				return Observable.just(event!.objectID)
			}).observeOn(MainScheduler.instance)
		
		inFlightEventObservables[identifier] = observable
		
		return observable
	}
	
	func getEvent(forManagedObjectID managedObjectID: NSManagedObjectID, completion: (PortlEvent?) -> Void) {
		let result = persistentContainer.viewContext.object(with: managedObjectID) as? PortlEvent
		completion(result)
	}


    func getEvents(forIDs IDs: Array<String>) -> Observable<Array<String>> {
        var previouslyCached = Array<PortlEvent>()
        
        for ID in IDs {
			if let cached = checkCache(for: PortlEvent.self, withPredicate: PortlEvent.predicateForCacheLookup(identifier: ID), inContext: persistentContainer.viewContext) {
                previouslyCached.append(cached)
            }
        }
        
        let foundIDs = previouslyCached.map { (event) -> String in
            return event.identifier
        }
        
        let coveredByInFlight = IDs.filter { (ID) -> Bool in
            return inFlightProfileObservables.keys.contains(ID)
        }
        
        let remainingIDs = IDs.filter { (ID) -> Bool in
            return !foundIDs.contains(ID) && !coveredByInFlight.contains(ID)
        }
        
        let query = EventsByIDsQuery(id: remainingIDs, pageSize: remainingIDs.count)
        var returnedIDs = Array<String>()
        
        if remainingIDs.count == 0 {
            return Observable.just(coveredByInFlight + foundIDs)
        }
		
		let context = newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        
        let observable = portlAPI.eventsByIdentifiers(with: query)
            .flatMap({ [unowned self] json -> Observable<Array<String>> in
                guard let eventsValues = json["events"] as? Array<Dictionary<String, Any?>>  else {
                    return Observable.just([])
                }
                
                for eventValues in eventsValues {
					if let eventEntity = try self.deserializeAndSaveEntity(of: PortlEvent.self, forJson: eventValues, inContext: context) {
                        returnedIDs.append(eventEntity.identifier)
                    }
                }
                
                for ID in remainingIDs {
                    self.inFlightProfileObservables.removeValue(forKey: ID)
                }
                
                return Observable.just(foundIDs + coveredByInFlight + returnedIDs)
            })
            .observeOn(MainScheduler.instance)
        
        for ID in remainingIDs {
            inFlightProfileObservables[ID] = observable
        }
        
        return observable
    }
    
    func getNextPageOfEventCategorySearch(forEventSearchObjectId managedObjectId: NSManagedObjectID) -> Observable<NSManagedObjectID>? {
		let context = persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        guard let search = context.object(with: managedObjectId) as? EventSearch, let date = search.startingAfter?.timeIntervalSince1970, let category = search.categories, let pages = search.searchPages as! Set<SearchPage>? else {
            print("Error building query for search page")
            return nil
        }
        
        let totalRetrieved = pages.map{$0.searchItems?.count ?? 0}.reduce(0, +)
        
        if search.totalCount == totalRetrieved {
            return Observable.just(managedObjectId)
        }
        
        let cacheHash = "\(search.latitude)\(search.longitude)\(date)\(search.startingWithinDays ?? -1)\(search.maxDistanceMiles)100\(category)"
        
        // check for in-flight observable
        
        if let inFlight = inFlightSearchObservables[cacheHash] {
            return inFlight
        }
        
        let query = EventCategoryQuery(location: Location(lat: search.latitude, lng: search.longitude),
                                       maxDistanceMiles: search.maxDistanceMiles,
                                       startingAfter: Int64(date),
									   startingWithinDays: search.startingWithinDays,
                                       categories: [category],
                                       page: pages.count)
        
        let observable = portlAPI.eventCategorySearch(with: query)
            .flatMap({ [unowned self] (json) -> Observable<NSManagedObjectID> in
				let searchEntity = try self.deserializeAndSaveEntity(of: EventSearch.self, forJson: json, inContext: context)
                self.inFlightSearchObservables.removeValue(forKey: cacheHash)
                return Observable.just(searchEntity!.objectID)
            })
            .observeOn(MainScheduler.instance)
        
        inFlightSearchObservables[cacheHash] = observable
        return observable
    }
    
    // MARK: Requests (Artist)
    
    func getArtist(forIdentifier identifier: String) -> Observable<NSManagedObjectID> {
		let context = persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

		// check for in-flight observable
        
        if let inFlight = inFlightSearchObservables[identifier] {
            return inFlight
        }
        
        // look in core data
        
		if let cached = checkCache(for: ArtistById.self, withPredicate: ArtistById.predicateForCacheLookup(identifier: identifier), inContext: context) {
            return Observable.just(cached.objectID)
        }
        
        let observable = portlAPI.artistByIdentifier(with: IdQuery(identifier: identifier))
            .flatMap({ [unowned self] (json) -> Observable<NSManagedObjectID> in
				let artistByIdEntity = try self.deserializeAndSaveEntity(of: ArtistById.self, forJson: json, inContext: context)
                self.inFlightSearchObservables.removeValue(forKey: identifier)
                return Observable.just(artistByIdEntity!.objectID)
            }).observeOn(MainScheduler.instance)
        
        inFlightSearchObservables[identifier] = observable
        
        return observable
    }
    
	func getArtists(forKeyword keyword: String) -> Observable<NSManagedObjectID> {
		let context = persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        let lowered = keyword.lowercased()
        
        let cacheKey = "artist:\(lowered)"
        if let inFlight = inFlightSearchObservables[cacheKey] {
            return inFlight
        }
		
		let keywordQuery = KeywordQuery(name: lowered, page: 0)
		
		if let cached = checkCache(for: ArtistKeywordSearch.self, withPredicate: ArtistKeywordSearch.predicateForCacheLookup(keyword: lowered, pageSize: keywordQuery.pageSize), inContext: context) {
            return Observable.just(cached.objectID)
        }
		
		let observable = portlAPI.artistByKeyword(with: keywordQuery)
            .flatMap({ [unowned self] (json) -> Observable<NSManagedObjectID> in
				let artistByKeywordEntity = try self.deserializeAndSaveEntity(of: ArtistKeywordSearch.self, forJson: json, inContext: context)
                self.inFlightSearchObservables.removeValue(forKey: cacheKey)
                return Observable.just(artistByKeywordEntity!.objectID)
            }).observeOn(MainScheduler.instance)
        
        inFlightSearchObservables[cacheKey] = observable
        
        return observable
    }
    
    func getNextPageOfArtistKeywordSearch(forArtistKeywordSearchObjectID managedObjectID: NSManagedObjectID) -> Observable<NSManagedObjectID>? {
		let context = persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        guard let search = context.object(with: managedObjectID) as? ArtistKeywordSearch, let pages = search.searchPages as? Set<SearchPage> else {
            print("Error building query for artist keyword search page")
            return nil
        }
        
        let totalRetrieved = pages.map{$0.searchItems?.count ?? 0}.reduce(0, +)
        
        if search.totalCount == totalRetrieved {
            return Observable.just(managedObjectID)
        }
        
        let cacheHash = "artist:\(search.keyword)"
        
        if let inFlight = inFlightSearchObservables[cacheHash] {
            return inFlight
        }
        
		let query = KeywordQuery(name: search.keyword, page: search.searchPages!.count)
        
        let observable = portlAPI.artistByKeyword(with: query)
            .flatMap({ [unowned self] (json) -> Observable<NSManagedObjectID> in
				let searchEntity = try self.deserializeAndSaveEntity(of: ArtistKeywordSearch.self, forJson: json, inContext: context)
                self.inFlightSearchObservables.removeValue(forKey: cacheHash)
                return Observable.just(searchEntity!.objectID)
            })
            .observeOn(MainScheduler.instance)
        
        inFlightSearchObservables[cacheHash] = observable
        return observable
    }
    
    // MARK: Requests (Venue)
    
    func getVenue(forIdentifier identifier: String) -> Observable<NSManagedObjectID> {
		let context = persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

		// check for in-flight observable
        
        if let inFlight = inFlightSearchObservables[identifier] {
            return inFlight
        }
        
        // look in core data
        
		if let cached = checkCache(for: VenueById.self, withPredicate: VenueById.predicateForCacheLookup(identifier: identifier), inContext: context) {
            return Observable.just(cached.objectID)
        }
        
        let observable = portlAPI.venueByIdentifier(with: IdQuery(identifier: identifier))
            .flatMap({ [unowned self] (json) -> Observable<NSManagedObjectID> in
				let venueByIdEntity = try self.deserializeAndSaveEntity(of: VenueById.self, forJson: json, inContext: context)
                self.inFlightSearchObservables.removeValue(forKey: identifier)
                return Observable.just(venueByIdEntity!.objectID)
            }).observeOn(MainScheduler.instance)
        
        inFlightSearchObservables[identifier] = observable
        
        return observable
    }
    
	func getVenues(forKeyword keyword: String, location: CLLocation, withinDistance: Double) -> Observable<NSManagedObjectID> {
		let context = persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        let lowered = keyword.lowercased()
        let latitude = location.coordinate.latitude
		let longitude = location.coordinate.longitude
		
        let cacheKey = "venue:\(lowered)\(latitude)\(longitude)\(withinDistance)"
        if let inFlight = inFlightSearchObservables[cacheKey] {
            return inFlight
        }
		
		let keywordQuery = KeywordQuery(name: lowered, page: 0, location: Location(lat: latitude, lng: longitude), withinDistance: withinDistance)
        
		if let cached = checkCache(for: VenueKeywordSearch.self, withPredicate: VenueKeywordSearch.predicateForCacheLookup(keyword: lowered, pageSize: keywordQuery.pageSize, lat: latitude, lng: longitude, withinDistance: withinDistance), inContext: context) {
            return Observable.just(cached.objectID)
        }
		
        let observable = portlAPI.venueByKeyword(with: keywordQuery)
            .flatMap({ [unowned self] (json) -> Observable<NSManagedObjectID> in
				var jsonWithLatLng = json
				jsonWithLatLng["lat"] = latitude
				jsonWithLatLng["lng"] = longitude
				let venueByKeywordEntity = try self.deserializeAndSaveEntity(of: VenueKeywordSearch.self, forJson: jsonWithLatLng, inContext: context)
                self.inFlightSearchObservables.removeValue(forKey: cacheKey)
                return Observable.just(venueByKeywordEntity!.objectID)
            }).observeOn(MainScheduler.instance)
        
        inFlightSearchObservables[cacheKey] = observable
        
        return observable
    }
    
    func getNextPageOfVenueKeywordSearch(forVenueKeywordSearchObjectID managedObjectID: NSManagedObjectID) -> Observable<NSManagedObjectID>? {
		let context = persistentContainer.newBackgroundContext()
		context.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        guard let search = context.object(with: managedObjectID) as? VenueKeywordSearch, let pages = search.searchPages as? Set<SearchPage> else {
            print("Error building query for artist keyword search page")
            return nil
        }
        
        let totalRetrieved = pages.map{$0.searchItems?.count ?? 0}.reduce(0, +)
        
        if search.totalCount == totalRetrieved {
            return Observable.just(managedObjectID)
        }
        
        let cacheHash = "venue:\(search.keyword)\(search.lat)\(search.lng)"
        
        if let inFlight = inFlightSearchObservables[cacheHash] {
            return inFlight
        }
        
		let query = KeywordQuery(name: search.keyword, page: search.searchPages!.count, location: Location(lat:search.lat, lng:search.lng))
        
        let observable = portlAPI.venueByKeyword(with: query)
            .flatMap({ [unowned self] (json) -> Observable<NSManagedObjectID> in
				var jsonWithLatLng = json
				jsonWithLatLng["lat"] = search.lat
				jsonWithLatLng["lng"] = search.lng

				let searchEntity = try self.deserializeAndSaveEntity(of: VenueKeywordSearch.self, forJson: jsonWithLatLng, inContext: context)
                self.inFlightSearchObservables.removeValue(forKey: cacheHash)
                return Observable.just(searchEntity!.objectID)
            })
            .observeOn(MainScheduler.instance)
        
        inFlightSearchObservables[cacheHash] = observable
        return observable
    }
    
    // MARK: Results Controllers
	
	private func fetch(searchWithID searchID: NSManagedObjectID) -> Search {
		return persistentContainer.viewContext.object(with: searchID) as! Search
	}
	
	private func fetch(searchPagesWithIDs searchPageIDs: [NSManagedObjectID]) -> [SearchPage] {
		let searchPageRequest: NSFetchRequest<SearchPage> = SearchPage.fetchRequest()
		searchPageRequest.predicate = NSPredicate(format: "self IN %@", searchPageIDs)
		return (try? persistentContainer.viewContext.fetch(searchPageRequest)) ?? []
	}
	
	private func getSearchItemIDs(forSearchObjectID searchObjectID: NSManagedObjectID) -> [NSManagedObjectID] {
		let pageIDs = (fetch(searchWithID: searchObjectID).searchPages as? Set<SearchPage>)?.map { $0.objectID } ?? []
		return (fetch(searchPagesWithIDs: pageIDs)).flatMap { ($0.searchItems as? Set<SearchItem>)?.map { item in item.objectID} ?? []}
	}
    func fetchedResultsController(forEventSearchObjectId managedObjectId: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<EventSearchItem>? {
		let eventIDs = getSearchItemIDs(forSearchObjectID: managedObjectId)
		
		let fetchRequest: NSFetchRequest<EventSearchItem> = EventSearchItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "self IN %@ ", eventIDs)
		fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "event.localStartDate", ascending: true), NSSortDescriptor(key: "distance", ascending: true)]
        return fetchedResultsController(for: fetchRequest, delegate: delegate, errorMessage: "Could not create results controller for search")
    }
    
    func fetchedResultsControllerWithDateSections(forEventSearchObjectId managedObjectId: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<EventSearchItem>? {
		let eventIDs = getSearchItemIDs(forSearchObjectID: managedObjectId)

		let fetchRequest: NSFetchRequest<EventSearchItem> = EventSearchItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "self IN %@", eventIDs)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "event.localStartDate", ascending: true), NSSortDescriptor(key: "distance", ascending: true)]
        
        return fetchedResultsController(for: fetchRequest, sectionNameKeyPath: "startDate", delegate: delegate, errorMessage: "Could not create results controller for search")        
    }
    
    func fetchedResultsController(forEventIDs eventIDs: Array<String>, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<PortlEvent>? {
		let predicate = NSPredicate(format: "%@ CONTAINS identifier", eventIDs)
        return eventIDsFetchedResultsController(delegate: delegate, predicate: predicate)
    }
	
	func fetchedResultsControllerForPastEvents(inEventIDs eventIDs: Array<String>, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<PortlEvent>? {
		let predicate = NSPredicate(format: "%@ CONTAINS identifier AND startDateTime < %@", eventIDs, Date() as NSDate)
		return eventIDsFetchedResultsController(delegate: delegate, predicate: predicate)
	}
	
	func fetchedResultsControllerForFutureEvents(inEventIDs eventIDs: Array<String>, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<PortlEvent>? {
		let predicate = NSPredicate(format: "%@ CONTAINS identifier AND startDateTime >= %@", eventIDs, Date() as NSDate)
		let sortDescriptors = [NSSortDescriptor(key: "startDateTime", ascending: true)]
		return eventIDsFetchedResultsController(delegate: delegate, predicate: predicate, sortDescriptors: sortDescriptors)
	}
	
	private func eventIDsFetchedResultsController(delegate: NSFetchedResultsControllerDelegate, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]? = nil) -> NSFetchedResultsController<PortlEvent>? {
		let fetchRequest: NSFetchRequest<PortlEvent> = PortlEvent.fetchRequest()
		fetchRequest.predicate = predicate
		fetchRequest.sortDescriptors = sortDescriptors ?? [NSSortDescriptor(key: "startDateTime", ascending: false)]
		
		return fetchedResultsController(for: fetchRequest, delegate: delegate, errorMessage: "Could not create results controller for events by ID")
	}

    func fetchedResultsController(forArtistByIdObjectId managedObjectId: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate, past: Bool) -> NSFetchedResultsController<PortlEvent>? {
        let fetchRequest: NSFetchRequest<PortlEvent> =  PortlEvent.fetchRequest()
        let inequality = past ? "<" : ">="
        fetchRequest.predicate = NSPredicate(format: "artistQueries CONTAINS %@ AND startDateTime \(inequality) %@", argumentArray: [managedObjectId, NSDate()])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDateTime", ascending: true)]
        
        return fetchedResultsController(for: fetchRequest, delegate: delegate, errorMessage: "Could not create results controller for artist events")
    }
    
    func fetchedResultsController(forArtistByKeywordObjectID managedObjectID: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<ArtistKeywordSearchItem>? {
		let artistIDs = getSearchItemIDs(forSearchObjectID: managedObjectID)

		let fetchRequest: NSFetchRequest<ArtistKeywordSearchItem> = ArtistKeywordSearchItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "self IN %@", artistIDs)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "artist.name", ascending: true)]
        
        return fetchedResultsController(for: fetchRequest, delegate: delegate, errorMessage: "Could not create results controller for artist by keyword results")
    }
    
    func fetchedResultsController(forVenueByIdObjectId managedObjectId: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate, past: Bool) -> NSFetchedResultsController<PortlEvent>? {
        let fetchRequest: NSFetchRequest<PortlEvent> = PortlEvent.fetchRequest()
        let inequality = past ? "<" : ">="
        fetchRequest.predicate = NSPredicate(format: "venueQueries CONTAINS %@ AND startDateTime \(inequality) %@", argumentArray: [managedObjectId, NSDate()])
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startDateTime", ascending: true)]
        
        return fetchedResultsController(for: fetchRequest, delegate: delegate, errorMessage: "Could not create results controller for venue events")
    }
    
    func fetchedResultsController(forVenueByKeywordObjectID managedObjectID: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<VenueKeywordSearchItem>? {
		let venueIDs = getSearchItemIDs(forSearchObjectID: managedObjectID)

		let fetchRequest: NSFetchRequest<VenueKeywordSearchItem> = VenueKeywordSearchItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "self IN %@", venueIDs)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "distanceFromUserMeters", ascending: true)]
        
        return fetchedResultsController(for: fetchRequest, delegate: delegate, errorMessage: "Could not create results controller for venue by keyword results")
    }
    
    func fetchedResultsControllerForPortlCategories(delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<PortlCategory>? {
        let fetchRequest: NSFetchRequest<PortlCategory> = PortlCategory.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "defaultIndex", ascending: true)]
        
        return fetchedResultsController(for: fetchRequest, delegate: delegate, errorMessage: "Could not create results controller for PortlCategory")
    }
    
    // MARK: ManagedObjectDecodableService
	
	// MARK: ProvidesLocalStartDateFormatter
	
	func getLocalStartDate(fromString string: String) -> NSDate {
		return localStartDateFormatter.date(from: string)! as NSDate
	}
	
    // MARK: Private
    
	private func checkCache<T>(for type: T.Type, withPredicate predicate: NSPredicate, inContext context: NSManagedObjectContext) -> T? where T: Cacheable {
        let fetchRequest = T.fetchRequest()
        fetchRequest.fetchLimit = 1
        fetchRequest.includesPropertyValues = false
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.predicate = predicate
		
        do {
            if let found = try context.fetch(fetchRequest).first as? T {
                let calendar = Calendar.current
                
                if (found.timestamp as Date) > calendar.date(byAdding: DateComponents(day: -1), to: Date())! {
					// valid cached object less than a day old
                    return found
                }
            }
        } catch let thrownError {
            print("Error looking up cached \(T.entity().name!) : \(thrownError.localizedDescription)")
        }
        
        return nil
    }
    
	private func deserializeEntity<T>(of type: T.Type, forJson json: Any, inContext context: NSManagedObjectContext, shouldSave: Bool) throws -> T? where T: NSManagedObject, T: ManagedObjectDecodable {
        var error: Error? = nil
        var entity: T? = nil
        context.performAndWait { [unowned self] in
            guard let entityValues = json as? Dictionary<String, Any> else {
                print("\(json)")
                error = ValidationError.validationFailed(entityName: T.entity().name!, attributeName: "\(T.entity().name!) values", reason: "de-serialization failed")
                return
            }
            
            do {
                entity = try self.managedObject(of: T.self, forValues: entityValues, in: context)
            } catch let thrownError {
                print("Error parsing entity \(T.entity().name!): \(thrownError)")
                error = thrownError
            }
            
            if shouldSave {
                do {
                    try context.save()
                } catch let thrownError {
                    error = thrownError
                }
            }
        }
        
        guard error == nil else {
            throw error!
        }
        
        return entity
    }
	
	private func deserializeEntity<T>(of type: T.Type, forValues values: Dictionary<String, Any>, inContext context: NSManagedObjectContext, shouldSave: Bool) throws -> T? where T: NSManagedObject, T: ManagedObjectDecodable {
		var error: Error? = nil
		var entity: T? = nil
		context.performAndWait { [unowned self] in
			do {
				entity = try self.managedObject(of: T.self, forValues: values, in: context)
			} catch let thrownError {
				print("Error parsing entity \(T.entity().name!): \(thrownError)")
				error = thrownError
			}
			
			if shouldSave {
				do {
					try context.save()
				} catch let thrownError {
					error = thrownError
				}
			}
		}
		
		guard error == nil else {
			throw error!
		}
		
		return entity
	}
    
	private func deserializeAndSaveEntity<T>(of type: T.Type, forJson json: Any, inContext context: NSManagedObjectContext) throws -> T? where T: NSManagedObject, T: ManagedObjectDecodable {
		return try deserializeEntity(of: T.self, forJson: json, inContext: context, shouldSave: true)
    }
    
    private func predicateForLookup<T>(_ type: T.Type, attributes: Dictionary<String, Any>) -> NSPredicate? where T: NSManagedObject {
        let predicate: NSPredicate?
        if !attributes.isEmpty {
            var predicateFormatString = ""
            var attributeValues = Array<Any>()
            for (key, value) in attributes {
                if !predicateFormatString.isEmpty  {
                    predicateFormatString += " AND "
                }
                
                if value is NSNull {
                    predicateFormatString += "\(key) == NIL"
                } else if key == "latitude" || key == "longitude" {
                    predicateFormatString += "(%@ <= \(key)) AND (\(key) <= %@)"
                    attributeValues.append(contentsOf: [value as! Double - 0.0001, value as! Double + 0.0001])
                } else {
                    predicateFormatString += "\(key) == %@"
                    attributeValues.append(value)
                }
            }
            
            predicate = NSPredicate(format: predicateFormatString, argumentArray: attributeValues)
        } else {
            predicate = nil
        }
        
        return predicate
    }
    
    private func lookup<T>(_ type: T.Type, withPredicate predicate: NSPredicate?, in context: NSManagedObjectContext) throws -> T? where T: NSManagedObject {
        guard let predicate = predicate else {
            return nil
        }

        let fetchRequest = T.fetchRequest() as! NSFetchRequest<T>
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.predicate = predicate

        return try context.fetch(fetchRequest).first as T?
    }
	
    private func lookupOrCreate<T>(_ type: T.Type, withIdentifyingAttributes identifyingAttributes: Dictionary<String, Any>, in context: NSManagedObjectContext) throws -> T where T: NSManagedObject {
        let predicate: NSPredicate?
        predicate = predicateForLookup(T.self, attributes: identifyingAttributes)
        
        return try lookupOrCreate(T.self, with: predicate, andAttributesToAssign: identifyingAttributes, in: context)
    }
    
    private func lookupOrCreate<T>(_ type: T.Type, with predicate: NSPredicate?, andAttributesToAssign attributes: Dictionary<String, Any>, in context: NSManagedObjectContext) throws -> T where T: NSManagedObject {
        guard let predicate = predicate else {
            return try create(T.self, withAttributesToAssign: attributes, in: context)
        }
        
        let result: T
        if let entity = try lookup(T.self, withPredicate: predicate, in: context) {
            result = entity
        } else {
            result = try create(T.self, withAttributesToAssign: attributes, in: context)
        }
        
        return result
    }
	
    // MARK: Initialization
    
	public init(persistentContainer: NSPersistentContainer, sessionManager: SessionManager, portlAPI: PortlAPI, localStartDateFormatter: DateFormatter) {
        self.sessionManager = sessionManager
        self.portlAPI = portlAPI
        self.localStartDateFormatter = localStartDateFormatter
		
		super.init(persistentContainer: persistentContainer)
		
        getPortlCategories().subscribe().disposed(by: disposeBag)
	}
	
    // MARK: Properties (Injected)
    
    private let sessionManager: SessionManager
    private let portlAPI: PortlAPI
    private let localStartDateFormatter: DateFormatter
    private let disposeBag = DisposeBag()
	
    // MARK: Properties (Private)
    private var inFlightSearchObservables = Dictionary<String, Observable<NSManagedObjectID>>()
    private var inFlightEventObservables = Dictionary<String, Observable<NSManagedObjectID>>()
    private var inFlightProfileObservables = Dictionary<String, Observable<Array<String>>>()
}
