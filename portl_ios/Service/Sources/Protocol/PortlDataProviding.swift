//
//  PortlDataProviding.swift
//  Service
//
//  Created by Jeff Creed on 3/21/18.
//  Copyright © 2018 Portl. All rights reserved.
//

import CoreData
import RxSwift
import CoreLocation

public protocol PortlDataProviding {
    func getPortlCategories() -> Observable<Void>
    
	func getEvents(forCategory category: String, location: CLLocation, distance: Double, startDate: Date, withinDays: Int?, page: Int) -> Observable<NSManagedObjectID>
	func getEvents(forCategories categories: Array<String>, location: CLLocation, distance: Double, startDate: Date, withinDays: Int?,  page: Int) -> Observable<NSManagedObjectID>
    func getNextPageOfEventCategorySearch(forEventSearchObjectId managedObjectId: NSManagedObjectID) -> Observable<NSManagedObjectID>?
    func getEvents(forIDs IDs: Array<String>) -> Observable<Array<String>>
	func getEvent(forIdentifier identifier: String) -> Observable<NSManagedObjectID>
	func getEvent(forManagedObjectID managedObjectID: NSManagedObjectID, completion: (PortlEvent?) -> Void)
	
    func fetchedResultsController(forEventSearchObjectId managedObjectId: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<EventSearchItem>?
    func fetchedResultsControllerWithDateSections(forEventSearchObjectId managedObjectId: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<EventSearchItem>?
    func fetchedResultsController(forEventIDs eventIDs: Array<String>, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<PortlEvent>?
	func fetchedResultsControllerForPastEvents(inEventIDs eventIDs: Array<String>, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<PortlEvent>?
	func fetchedResultsControllerForFutureEvents(inEventIDs eventIDs: Array<String>, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<PortlEvent>?
	
    func getArtist(forIdentifier identifier: String) -> Observable<NSManagedObjectID>
    func getArtists(forKeyword keyword: String) -> Observable<NSManagedObjectID> 
    func getNextPageOfArtistKeywordSearch(forArtistKeywordSearchObjectID managedObjectID: NSManagedObjectID) -> Observable<NSManagedObjectID>?

    func fetchedResultsController(forArtistByIdObjectId managedObjectId: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate, past: Bool) -> NSFetchedResultsController<PortlEvent>?
    func fetchedResultsController(forArtistByKeywordObjectID managedObjectID: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<ArtistKeywordSearchItem>? 

    func getVenue(forIdentifier identifier: String) -> Observable<NSManagedObjectID>
	func getVenues(forKeyword keyword: String, location: CLLocation, withinDistance: Double) -> Observable<NSManagedObjectID>
    func getNextPageOfVenueKeywordSearch(forVenueKeywordSearchObjectID managedObjectID: NSManagedObjectID) -> Observable<NSManagedObjectID>?

    func fetchedResultsController(forVenueByIdObjectId managedObjectId: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate, past: Bool) -> NSFetchedResultsController<PortlEvent>?
    func fetchedResultsController(forVenueByKeywordObjectID managedObjectID: NSManagedObjectID, delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<VenueKeywordSearchItem>?
    
    func fetchedResultsControllerForPortlCategories(delegate: NSFetchedResultsControllerDelegate) -> NSFetchedResultsController<PortlCategory>?
	
	func clearCachedEvents()
}
